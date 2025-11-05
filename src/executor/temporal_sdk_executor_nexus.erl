-module(temporal_sdk_executor_nexus).
-behaviour(gen_statem).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    start/3
]).
-export([
    init/1,
    terminate/3,
    callback_mode/0
]).
-export([
    execute/3,
    await_data/3,
    complete_task/3,
    cancel_task/3,
    fail_task/3
]).

-include("temporal_sdk_executor.hrl").
-include("sdk.hrl").
-include("telemetry.hrl").

-define(EVENT_ORIGIN, nexus).

-define(LINKED_PID_EXIT_REASON, nexus_execution_terminated).

%% -------------------------------------------------------------------------------------------------
%% state record

-record(state, {
    %% --------------- input
    api_ctx :: temporal_sdk_api:context(),
    task :: temporal_sdk_nexus:task(),
    task_module :: module(),
    %% --------------- task
    data :: temporal_sdk_nexus:data(),
    task_timeout :: erlang:timeout(),
    cancel_requested = false :: boolean(),
    task_result = [] :: temporal_sdk:term_to_payloads(),
    closed_state = error :: error | completed | canceled | failed | invalid,
    %% --------------- executor
    proc_label :: string(),
    stop_reason = normal :: normal | temporal_sdk_telemetry:exception(),
    execution_pid = undefined :: undefined | pid(),
    awaiter = undefined :: undefined | gen_statem:from(),
    await_pattern = undefined :: undefined | ets:compiled_match_spec(),
    handle_cancel_pid = undefined :: undefined | pid(),
    %% --------------- telemetry
    started_at = 0 :: integer(),
    otel_ctx :: otel_ctx:t(),
    ev_metadata :: map()
}).
-type state() :: #state{}.

%% -------------------------------------------------------------------------------------------------
%% gen_statem

-spec start(
    ApiContext :: temporal_sdk_api:context(),
    TemporalTask :: temporal_sdk_nexus:task(),
    TaskMod :: module()
) -> gen_statem:start_ret().
start(ApiContext, TemporalTask, TaskMod) ->
    gen_statem:start(?MODULE, [ApiContext, TemporalTask, TaskMod], []).

init([ApiContext, Task, TaskMod]) ->
    process_flag(trap_exit, true),

    #{
        cluster := Cluster,
        worker_opts := #{
            worker_id := WorkerId,
            namespace := Namespace,
            task_queue := TaskQueue,
            task_settings := #{data := TaskSettingsData}
        } = WorkerOpts,
        worker_identity := WorkerIdentity,
        limiter_counters := [LimiterCounters]
    } = ApiContext,
    #{
        request := #{
            scheduled_time := ScheduledTime,
            variant := {start_operation, #{operation := Operation, service := Service}}
        },
        task_token := _TaskToken
    } = Task,
    ProcLabel = temporal_sdk_utils_path:string_path([
        ?MODULE,
        Cluster,
        Namespace,
        TaskQueue,
        Service,
        Operation
    ]),
    proc_lib:set_label(ProcLabel),
    temporal_sdk_limiter:inc(LimiterCounters),

    SdkData = temporal_sdk_api_nexus_task:fetch_header_sdk_data(Task),

    SD = #state{
        %% --------------- input
        api_ctx = ApiContext,
        task = Task,
        task_module = TaskMod,
        %% --------------- task
        data = TaskSettingsData,
        task_timeout = fetch_task_timeout(WorkerOpts, Task),
        %% cancel_requested = false
        %% task_result = []
        %% closed_state = error
        %% --------------- executor
        proc_label = ProcLabel,
        %% stop_reason = normal
        %% execution_pid = undefined
        %% awaiter = undefined
        %% await_pattern = undefined
        %% handle_cancel_pid = undefined
        %% --------------- telemetry
        %% started_at = 0
        otel_ctx = maps:get(otel_context, SdkData, #{}),
        ev_metadata = #{
            cluster => Cluster,
            worker_id => WorkerId,
            namespace => Namespace,
            task_queue => TaskQueue,
            service => Service,
            operation => Operation,

            worker_identity => WorkerIdentity,
            task_module => TaskMod,

            scheduled_time => temporal_sdk_utils_time:protobuf_to_nanos(ScheduledTime)
        }
    },
    T = ?EV(SD, [executor, start]),
    ?EV(SD, [task, start]),
    StateData = SD#state{started_at = T},
    {ok, execute, StateData}.

terminate(Reason, _State, StateData) ->
    #state{
        api_ctx = #{limiter_counters := [LimiterCounters]},
        task_module = TaskMod,
        ev_metadata = EvMetadata,
        started_at = StartedAt,
        stop_reason = StopReason,
        closed_state = ClosedState
    } = StateData,
    SD = cleanup(StateData#state{ev_metadata = EvMetadata#{closed_state => ClosedState}}),
    temporal_sdk_limiter:dec(LimiterCounters),
    case erlang:function_exported(TaskMod, terminate, 1) of
        true -> spawn(TaskMod, terminate, [build_handler_context(StateData)]);
        false -> ok
    end,

    case StopReason of
        normal -> ?EV(SD, [task, stop], StartedAt);
        _ -> ?EV(SD, [task, exception], StartedAt, StopReason)
    end,
    case Reason of
        normal -> ?EV(SD, [executor, stop], StartedAt);
        R -> ?EV(SD, [executor, exception], StartedAt, {error, R, []})
    end.

callback_mode() ->
    [state_functions, state_enter].

%% -------------------------------------------------------------------------------------------------
%% gen_statem state callbacks

execute(enter, execute, StateData) ->
    Pid = spawn_execution(StateData),
    {keep_state, StateData#state{execution_pid = Pid}, [
        {{timeout, task}, StateData#state.task_timeout, Pid}
    ]};
execute(enter, await_data, _StateData) ->
    keep_state_and_data;
execute({call, From}, {?MSG_API, Command}, StateData) ->
    handle_api_call(From, Command, StateData);
execute(cast, {?MSG_API, Command}, StateData) ->
    handle_api_cast(Command, StateData);
execute(cast, {?MSG_PRV, {execution_result, Result}}, StateData) ->
    {next_state, complete_task, StateData#state{task_result = Result}};
execute(cast, {?MSG_PRV, {execution_error, Error}}, StateData) ->
    {next_state, fail_task, StateData#state{stop_reason = Error}};
execute(EventType, EventContent, StateData) ->
    handle_common(?FUNCTION_NAME, EventType, EventContent, StateData).

await_data(enter, execute, _StateData) ->
    keep_state_and_data;
await_data(state_timeout, Awaiter, #state{awaiter = Awaiter} = StateData) ->
    {next_state, execute, StateData#state{awaiter = undefined, await_pattern = undefined},
        {reply, Awaiter, timeout}};
await_data(EventType, EventContent, StateData) ->
    handle_common(?FUNCTION_NAME, EventType, EventContent, StateData).

complete_task(enter, State, StateData) when State =:= execute; State =:= await_data ->
    #state{api_ctx = ApiCtx, task = Task, task_result = TaskResult} = StateData,
    temporal_sdk_api_nexus:respond_nexus_task_completed(ApiCtx, Task, TaskResult),
    {stop, normal, StateData#state{closed_state = completed}}.

cancel_task(enter, State, StateData) when State =:= execute; State =:= await_data ->
    #state{api_ctx = ApiCtx, task_result = TaskResult} = StateData,
    temporal_sdk_api_nexus:respond_nexus_task_canceled(ApiCtx, TaskResult),
    {stop, normal, StateData#state{closed_state = canceled}}.

fail_task(enter, State, StateData) when State =:= execute; State =:= await_data ->
    #state{api_ctx = ApiCtx, stop_reason = StopReason} = StateData,
    temporal_sdk_api_nexus:respond_nexus_task_failed(ApiCtx, StopReason),
    {stop, normal, StateData#state{closed_state = failed}}.

%% -------------------------------------------------------------------------------------------------
%% handle task commands

handle_api_call({Pid, _Ref} = F, {await_data, P, T}, #state{execution_pid = Pid} = StateData) ->
    Data = StateData#state.data,
    case temporal_sdk_utils_ets:run_match_spec(P, Data) of
        true ->
            {keep_state, StateData, {reply, F, {ok, Data}}};
        false ->
            {next_state, await_data, StateData#state{awaiter = F, await_pattern = P},
                {state_timeout, T, F}}
    end;
handle_api_call(_From, {complete, Result}, StateData) ->
    {next_state, complete_task, StateData#state{task_result = Result}};
handle_api_call(_From, {cancel, CanceledDetails}, StateData) ->
    {next_state, cancel_task, StateData#state{task_result = CanceledDetails}};
handle_api_call(_From, {fail, AppFailure}, StateData) ->
    #state{api_ctx = ApiCtx} = StateData,
    temporal_sdk_api_nexus:respond_nexus_task_failed(ApiCtx, AppFailure),
    {stop, normal, StateData#state{closed_state = failed}};
handle_api_call(From, {cancel_requested}, StateData) ->
    {keep_state_and_data, {reply, From, StateData#state.cancel_requested}};
handle_api_call(From, {elapsed_time}, StateData) ->
    {keep_state_and_data, {reply, From, elapsed_time(StateData)}};
handle_api_call(From, {remaining_time}, StateData) ->
    {keep_state_and_data, {reply, From, remaining_time(StateData)}};
handle_api_call(From, {get_data}, StateData) ->
    {keep_state_and_data, {reply, From, StateData#state.data}}.

handle_api_cast({set_data, Data}, StateData) ->
    {keep_state, StateData#state{data = Data}}.

%% -------------------------------------------------------------------------------------------------
%% handle_common OTP message
handle_common(State, info, {?TEMPORAL_SDK_OTP_TAG, Message}, StateData) when
    State =:= execute; State =:= await_data
->
    #state{task_module = TaskModule} = StateData,
    Context = build_handler_context(StateData),
    try
        case TaskModule:handle_message(Context, Message) of
            ignore ->
                keep_state_and_data;
            {complete, R} ->
                {next_state, complete_task, StateData#state{task_result = R}};
            {cancel, D} ->
                {next_state, cancel_task, StateData#state{task_result = D}};
            {fail, E} ->
                {next_state, fail_task, StateData#state{stop_reason = E}};
            {data, Data} ->
                Pattern = StateData#state.await_pattern,
                SD = StateData#state{data = Data},
                case State of
                    execute ->
                        {keep_state, SD};
                    await_data ->
                        case Pattern of
                            undefined ->
                                {next_state, fail_task, StateData#state{
                                    stop_reason =
                                        {error,
                                            "Expected compiled ets match spec, got <undefined>.",
                                            ?EVST}
                                }};
                            _ ->
                                case temporal_sdk_utils_ets:run_match_spec(Pattern, Data) of
                                    true ->
                                        {next_state, execute,
                                            SD#state{
                                                awaiter = undefined, await_pattern = undefined
                                            },
                                            {reply, SD#state.awaiter, {ok, Data}}};
                                    false ->
                                        {keep_state, SD}
                                end
                        end
                end
        end
    catch
        Class:Reason:Stacktrace ->
            {next_state, fail_task, StateData#state{stop_reason = {Class, Reason, Stacktrace}}}
    end;
handle_common(_State, info, {?TEMPORAL_SDK_OTP_TAG, _Message}, _StateData) ->
    keep_state_and_data;
%% -------------------------------------------------------------------------------------------------
%% handle_common task timeout
handle_common(_State, {timeout, task}, Pid, #state{execution_pid = Pid} = StateData) ->
    #state{
        api_ctx = #{worker_opts := #{task_settings := #{task_timeout_ratio := Ratio}}},
        task = Task,
        task_timeout = TaskTimeout
    } = StateData,
    SD = StateData#state{
        stop_reason =
            {error,
                {task_timeout, #{
                    executor_task_timeout => TaskTimeout,
                    executor_elapsed_time => erlang:convert_time_unit(
                        elapsed_time(StateData), native, millisecond
                    ),
                    task_timeouts => temporal_sdk_api_nexus_task:timeouts(Task),
                    task_timeout_ratio => Ratio
                }},
                ?EVST}
    },
    {next_state, fail_task, SD};
%% -------------------------------------------------------------------------------------------------
%% handle_common exits
handle_common(_State, info, {'EXIT', Pid, _Reason}, #state{execution_pid = Pid} = StateData) ->
    {keep_state, StateData#state{execution_pid = undefined}};
handle_common(_State, info, {'EXIT', Pid, _Reason}, #state{handle_cancel_pid = Pid} = StateData) ->
    {keep_state, StateData#state{handle_cancel_pid = undefined}};
handle_common(_State, info, {'EXIT', Pid, Reason}, StateData) ->
    {next_state, fail_task, StateData#state{
        stop_reason =
            {error, #{reason => "Linked process abnormal exit.", pid => Pid, exit_reason => Reason},
                ?EVST}
    }}.

%% -------------------------------------------------------------------------------------------------
%% spawn helpers

spawn_execution(StateData) ->
    #state{
        api_ctx = ApiContext,
        task = Task,
        task_module = TaskModule,
        otel_ctx = OtelCtx,
        proc_label = ProcLabel
    } = StateData,
    ExecutorPid = self(),
    ExecutionProcLabel = temporal_sdk_utils_path:string_path([ProcLabel, execution]),
    Context = build_context(StateData),
    Input = temporal_sdk_api_nexus_task:input(ApiContext, Task),
    T = ?EV(StateData, [execution, start]),
    spawn_link(fun() ->
        proc_lib:set_label(ExecutionProcLabel),
        temporal_sdk_executor:set_executor_dict(ExecutorPid),
        otel_ctx:attach(OtelCtx),
        % TODO start new otel span
        try
            Result = TaskModule:execute(Context, Input),
            ?EV(StateData, [execution, stop], T),
            gen_statem:cast(ExecutorPid, {?MSG_PRV, {execution_result, Result}})
        catch
            Class:Reason:Stacktrace ->
                ?EV(StateData, [execution, exception], T, {Class, Reason, Stacktrace}),
                gen_statem:cast(
                    ExecutorPid, {?MSG_PRV, {execution_error, {Class, Reason, Stacktrace}}}
                ),
                erlang:raise(Class, Reason, Stacktrace)
        end
    end).

% spawn_handler(StateData, HandlerFun, ResultTag, ErrorTag) ->
%     #state{task_module = TaskModule} = StateData,
%     ExecutorPid = self(),
%     Context = build_handler_context(StateData),
%     spawn_link(fun() ->
%         try
%             Result = TaskModule:HandlerFun(Context),
%             gen_statem:cast(ExecutorPid, {?MSG_PRV, {ResultTag, Result}})
%         catch
%             Class:Reason:Stacktrace ->
%                 gen_statem:cast(
%                     ExecutorPid, {?MSG_PRV, {ErrorTag, {Class, Reason, Stacktrace}}}
%                 ),
%                 erlang:raise(Class, Reason, Stacktrace)
%         end
%     end).

%% -------------------------------------------------------------------------------------------------
%% state helpers

-spec build_context(StateData :: state()) -> temporal_sdk_nexus:context().
build_context(StateData) ->
    #state{api_ctx = #{cluster := Cluster, worker_opts := WorkerOpts}} = StateData,
    #{operation := Operation} = temporal_sdk_api_nexus_task:start_operation(StateData#state.task),
    #{
        cluster => Cluster,
        executor_pid => self(),
        otel_ctx => StateData#state.otel_ctx,
        task => StateData#state.task,
        worker_opts => WorkerOpts,
        operation => Operation,
        started_at => StateData#state.started_at,
        task_timeout => StateData#state.task_timeout
    }.

-spec build_handler_context(StateData :: state()) -> temporal_sdk_nexus:handler_context().
build_handler_context(StateData) ->
    #{
        data => StateData#state.data,
        cancel_requested => StateData#state.cancel_requested,
        elapsed_time => elapsed_time(StateData),
        remaining_time => remaining_time(StateData)
    }.

cleanup(StateData) ->
    SD1 =
        case StateData#state.execution_pid of
            undefined ->
                StateData;
            Pid1 ->
                exit(Pid1, ?LINKED_PID_EXIT_REASON),
                StateData#state{execution_pid = undefined}
        end,
    case StateData#state.handle_cancel_pid of
        undefined ->
            SD1;
        Pid2 ->
            exit(Pid2, ?LINKED_PID_EXIT_REASON),
            SD1#state{handle_cancel_pid = undefined}
    end.

%% -------------------------------------------------------------------------------------------------
%% API helpers

elapsed_time(#state{started_at = StartedAt}) ->
    erlang:system_time() - StartedAt.

remaining_time(#state{task_timeout = infinity}) ->
    infinity;
remaining_time(#state{task_timeout = TaskTimeout, started_at = StartedAt}) ->
    T =
        erlang:convert_time_unit(TaskTimeout, millisecond, native) - erlang:system_time() +
            StartedAt,
    case T > 0 of
        true -> T;
        false -> 0
    end.

fetch_task_timeout(#{task_settings := #{task_timeout_ratio := Ratio}}, Task) ->
    case temporal_sdk_api_nexus_task:timeout(Task) of
        T when is_integer(T), T > 0 -> round(T * Ratio);
        _ -> infinity
    end.

%% -------------------------------------------------------------------------------------------------
%% telemetry

ev_origin() -> ?EVENT_ORIGIN.

ev_metadata(StateData) ->
    maps:merge(StateData#state.ev_metadata, build_handler_context(StateData)).
