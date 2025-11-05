-module(temporal_sdk_poller).
-behaviour(gen_statem).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    start_link/5
]).
-export([
    init/1,
    callback_mode/0
]).
-export([
    poll/3,
    wait/3
]).

-include("sdk.hrl").
-include("telemetry.hrl").

-define(EVENT_ORIGIN, poller).

%% -------------------------------------------------------------------------------------------------
%% state record

-record(state, {
    %% --------------- input
    api_ctx :: temporal_sdk_api:context(),
    limiter_counters :: temporal_sdk_limiter:counters(),
    poll_counter :: counters:counters_ref(),
    %% --------------- poller
    limiter_checks = [] :: temporal_sdk_limiter:checks(),
    limiter_wait_time = #{} :: #{
        {temporal_sdk_limiter:level(), temporal_sdk_limiter:limitable()} => pos_integer()
    },
    grpc_req_ref = undefined :: reference() | undefined,
    backoff_initial :: number(),
    backoff_current :: number(),
    capacity_check_interval :: pos_integer(),
    task_exec_interval :: number(),
    task_polled_at :: integer(),
    task_poll_status = undefined :: undefined | null | task | error,
    task_execute_status = undefined :: undefined | executed | redirected | failed,
    %% --------------- telemetry
    ev_metadata :: map(),
    ev_poll_at = 0 :: integer(),
    ev_wait_at = 0 :: integer()
}).

%% -------------------------------------------------------------------------------------------------
%% gen_statem

-spec start_link(
    ApiContext :: temporal_sdk_api:context(),
    LimiterCounters :: temporal_sdk_limiter:counters(),
    PollCounter :: counters:counters_ref(),
    WorkerSupPid :: pid(),
    W :: pos_integer()
) -> gen_statem:start_ret().
start_link(ApiContext, LimiterCounters, PollCounter, WorkerSupPid, W) ->
    gen_statem:start_link(?MODULE, [ApiContext, LimiterCounters, PollCounter, WorkerSupPid, W], []).

init([ApiContext, LimiterCounters, PollCounter, WorkerSupPid, W]) ->
    #{
        cluster := Cluster,
        worker_opts := #{
            worker_id := WorkerId,
            namespace := Namespace,
            task_queue := TQ,
            task_poller_limiter := TaskPollerLimiter,
            limits := Limits,
            limiter_check_frequency := LimiterCheckFrequency
        },
        worker_type := WorkerType
    } = ApiContext,
    ProcLabel = temporal_sdk_utils_path:string_path([?MODULE, Cluster, WorkerType, WorkerId, W]),
    proc_lib:set_label(ProcLabel),

    TaskExecInterval = task_exec_interval(TaskPollerLimiter),
    Backoff = max(TaskExecInterval, 1),

    StateData = #state{
        %% --------------- input
        api_ctx = ApiContext#{worker_identity => [WorkerId, WorkerType, W]},
        limiter_counters = LimiterCounters,
        poll_counter = PollCounter,
        %% --------------- poller
        %% limiter_checks = []
        %% limiter_wait_time = #{}
        %% grpc_req_ref = undefined
        backoff_initial = Backoff,
        backoff_current = Backoff,
        capacity_check_interval = LimiterCheckFrequency,
        task_exec_interval = TaskExecInterval,
        task_polled_at = erlang:monotonic_time(millisecond),
        %% task_poll_status = undefined
        %% task_execute_status = undefined
        %% --------------- telemetry
        ev_metadata = #{
            cluster => Cluster,
            namespace => Namespace,
            task_queue => TQ,
            worker_type => WorkerType,
            poller_id => [WorkerSupPid, W],
            worker_id => WorkerId
        }
        %% ev_poll_at = 0
        %% ev_wait_at = 0
    },
    case temporal_sdk_limiter:build_checks(Limits, LimiterCounters) of
        {ok, Checks} -> {ok, poll, StateData#state{limiter_checks = Checks}};
        Err -> {error, Err}
    end.

callback_mode() ->
    [state_functions, state_enter].

%% -------------------------------------------------------------------------------------------------
%% gen_statem state callbacks

poll(enter, poll, StateData) ->
    case is_allowed(StateData) of
        true ->
            handle_poll(StateData);
        _ ->
            gen_statem:cast(self(), backoff_normal),
            keep_state_and_data
    end;
poll(enter, wait, StateData) ->
    handle_poll(StateData);
poll(
    info,
    {?TEMPORAL_SDK_GRPC_TAG, Ref, {ok, #{task_token := TaskToken}}},
    #state{grpc_req_ref = Ref} = StateData
) when TaskToken =:= <<>>; TaskToken =:= "" ->
    ?EV(StateData#state{task_poll_status = null}, [poll, stop], StateData#state.ev_poll_at),
    poll_counter_dec(StateData),
    {repeat_state, StateData#state{backoff_current = StateData#state.backoff_initial}};
poll(
    info,
    {?TEMPORAL_SDK_GRPC_TAG, Ref, {ok, Task}},
    #state{grpc_req_ref = Ref} = StateData
) ->
    ?EV(StateData#state{task_poll_status = task}, [poll, stop], StateData#state.ev_poll_at),
    poll_counter_dec(StateData),
    T = ?EV(StateData, [execute, start]),
    case temporal_sdk_poller_adapter:handle_execute(StateData#state.api_ctx, Task) of
        {ok, Status} ->
            ?EV(
                StateData#state{task_poll_status = task, task_execute_status = Status},
                [execute, stop],
                T
            ),
            backoff_normal(StateData);
        Err ->
            ?EV(
                StateData#state{task_poll_status = task, task_execute_status = failed},
                [execute, exception],
                T,
                {error, Err, ?EVST}
            ),
            backoff_error(StateData)
    end;
poll(
    info,
    {?TEMPORAL_SDK_GRPC_TAG, Ref, Error},
    #state{grpc_req_ref = Ref} = StateData
) ->
    ?EV(
        StateData#state{task_poll_status = error},
        [poll, exception],
        StateData#state.ev_poll_at,
        {error, Error, ?EVST}
    ),
    poll_counter_dec(StateData),
    backoff_error(StateData);
poll(cast, {set_limits, NewLimits}, StateData) ->
    handle_set_limits(NewLimits, StateData);
poll(cast, backoff_normal, StateData) ->
    backoff_normal(StateData);
poll(cast, backoff_error, StateData) ->
    backoff_error(StateData).

handle_poll(StateData) ->
    T = ?EV(StateData, [poll, start]),
    case temporal_sdk_poller_adapter:handle_poll(StateData#state.api_ctx) of
        Ref when is_reference(Ref) ->
            poll_counter_inc(StateData),
            {keep_state, StateData#state{
                task_polled_at = erlang:monotonic_time(millisecond),
                grpc_req_ref = Ref,
                ev_poll_at = T,
                limiter_wait_time = #{}
            }};
        Err ->
            ?EV(StateData, [poll, exception], T, {error, Err, ?EVST}),
            gen_statem:cast(self(), backoff_error),
            keep_state_and_data
    end.

wait(enter, _State, StateData) ->
    T = ?EV(StateData, [wait, start]),
    {keep_state, StateData#state{ev_wait_at = T}};
wait(state_timeout, retry_timeout, StateData) ->
    case is_allowed(StateData) of
        true ->
            ?EV(StateData, [wait, stop], StateData#state.ev_wait_at),
            {next_state, poll, StateData};
        LevelLimitable ->
            {repeat_state, update_limiter_wait_time(LevelLimitable, StateData),
                {state_timeout, StateData#state.capacity_check_interval, retry_timeout}}
    end;
wait(cast, {set_limits, NewLimits}, StateData) ->
    handle_set_limits(NewLimits, StateData).

backoff_normal(StateData) ->
    Now = erlang:monotonic_time(millisecond),
    ElapsedTime = Now - StateData#state.task_polled_at,
    Timeout =
        case ElapsedTime >= StateData#state.task_exec_interval of
            true -> 0;
            false -> floor(StateData#state.task_exec_interval - ElapsedTime)
        end,
    {next_state, wait, StateData#state{backoff_current = StateData#state.backoff_initial},
        {state_timeout, Timeout, retry_timeout}}.

backoff_error(StateData) ->
    NewBackoff = max(2 * StateData#state.backoff_current, 1),
    {next_state, wait, StateData#state{backoff_current = NewBackoff},
        {state_timeout, floor(StateData#state.backoff_current), retry_timeout}}.

handle_set_limits(NewLimits, StateData) ->
    SD1 =
        case NewLimits of
            #{task_poller_limiter := TPL} ->
                StateData#state{task_exec_interval = task_exec_interval(TPL)};
            #{} ->
                StateData
        end,
    SD2 =
        maybe
            #{limits := L} ?= NewLimits,
            {ok, Checks} ?=
                temporal_sdk_limiter:build_checks(L, StateData#state.limiter_counters),
            SD1#state{limiter_checks = Checks}
        else
            _ -> SD1
        end,
    SD3 =
        case NewLimits of
            #{limiter_check_frequency := LCF} ->
                SD2#state{capacity_check_interval = LCF};
            #{} ->
                SD2
        end,
    {keep_state, SD3}.

%% -------------------------------------------------------------------------------------------------
%% helpers

poll_counter_inc(StateData) -> counters:add(StateData#state.poll_counter, 1, 1).

poll_counter_dec(StateData) -> counters:sub(StateData#state.poll_counter, 1, 1).

poll_counter_get(StateData) -> counters:get(StateData#state.poll_counter, 1).

is_allowed(StateData) ->
    #state{api_ctx = #{worker_type := WorkerType}, limiter_checks = LimiterChecks} = StateData,
    Checks = compensate_checks(
        LimiterChecks,
        poll_counter_get(StateData),
        temporal_sdk_worker_opts:worker_type_to_limitable(WorkerType)
    ),
    temporal_sdk_limiter:is_allowed(Checks).

compensate_checks(Checks, PollCount, Limitable) ->
    Fn = fun
        ({{Layer, Lim}, C, [MaxConcurrency, MaxFrequency]}) when
            Lim =:= Limitable, MaxFrequency >= PollCount
        ->
            {{Layer, Lim}, C, [MaxConcurrency, MaxFrequency - PollCount]};
        (Check) ->
            Check
    end,
    lists:map(Fn, Checks).

update_limiter_wait_time(LevelLimitable, StateData) ->
    #state{limiter_wait_time = LimiterWaitTime, capacity_check_interval = CapacityCheckInterval} =
        StateData,
    case LimiterWaitTime of
        #{LevelLimitable := T} ->
            StateData#state{
                limiter_wait_time = LimiterWaitTime#{LevelLimitable => T + CapacityCheckInterval}
            };
        #{} ->
            StateData#state{
                limiter_wait_time = LimiterWaitTime#{LevelLimitable => CapacityCheckInterval}
            }
    end.

task_exec_interval(#{limit := infinity, time_window := undefined}) ->
    0;
task_exec_interval(#{limit := Limit, time_window := {T, U}}) ->
    temporal_sdk_utils_time:convert_to_msec(T, U) / Limit;
task_exec_interval(#{limit := Limit, time_window := TimeWindow}) ->
    TimeWindow / Limit.

%% -------------------------------------------------------------------------------------------------
%% telemetry

ev_origin() -> ?EVENT_ORIGIN.

ev_metadata(StateData) ->
    Metadata = StateData#state.ev_metadata,
    Metadata#{
        task_poll_status => StateData#state.task_poll_status,
        task_execute_status => StateData#state.task_execute_status,
        limiter_wait_time => StateData#state.limiter_wait_time
    }.
