-module(temporal_sdk_executor_activity).
-behaviour(gen_statem).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    start/2,
    start_link/2
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

-define(EVENT_ORIGIN, activity).

-define(LINKED_PID_EXIT_REASON, activity_execution_terminated).

%% -------------------------------------------------------------------------------------------------
%% state record

-record(state, {
    %% --------------- input
    api_ctx :: temporal_sdk_api:context(),
    task :: temporal_sdk_activity:task(),
    execution_module :: module(),
    %% --------------- task
    data :: temporal_sdk_activity:data(),
    last_heartbeat = temporal_sdk_activity:heartbeat(),
    task_timeout :: erlang:timeout(),
    heartbeat_timeout :: erlang:timeout(),
    cancel_requested = false :: boolean(),
    activity_paused = false :: boolean(),
    task_result = [] :: temporal_sdk:term_to_payloads(),
    closed_state = error ::
        error
        | completed
        | canceled
        | direct_canceled
        | failed
        | invalid
        | direct_exit,
    task_user_data :: #{header => temporal_sdk:term_from_mapstring_payload()},
    %% --------------- executor
    workflow_executor_pid :: pid() | undefined,
    proc_label :: string(),
    stop_reason = normal :: normal | temporal_sdk_telemetry:exception(),
    execution_pid = undefined :: undefined | pid(),
    awaiter = undefined :: undefined | gen_statem:from(),
    await_pattern = undefined :: undefined | ets:compiled_match_spec(),
    handle_heartbeat_pid = undefined :: undefined | pid(),
    handle_heartbeat_ref = undefined :: undefined | reference(),
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
    TemporalTask :: temporal_sdk_activity:task()
) -> {ok, pid()} | {error, term()}.
start(ApiContext, TemporalTask) ->
    case gen_statem:start(?MODULE, [ApiContext, TemporalTask, undefined], []) of
        ignore -> {error, "Activity executor start ignored."};
        Ret -> Ret
    end.

-spec start_link(
    ApiContext :: temporal_sdk_api:context(),
    SyntheticTask :: temporal_sdk_activity:task()
) -> {ok, pid()} | {error, term()}.
start_link(ApiContext, SyntheticTask) ->
    case gen_statem:start_link(?MODULE, [ApiContext, SyntheticTask, self()], []) of
        ignore -> {error, "Activity executor start ignored."};
        Ret -> Ret
    end.

init([ApiContext, Task, WorkflowExecutorPid]) ->
    process_flag(trap_exit, true),

    #{
        cluster := Cluster,
        worker_opts := #{
            worker_id := WorkerId,
            namespace := Namespace,
            task_queue := TaskQueue,
            task_settings := #{
                data := TaskSettingsData,
                last_heartbeat := TaskSettingsLastHeartbeat
            }
        } = WorkerOpts,
        worker_identity := WorkerIdentity,
        limiter_counters := [LimiterCounters],
        execution_module := ExecutionModule
    } = ApiContext,
    #{
        workflow_namespace := WorkflowNamespace,
        workflow_type := #{name := WorkflowType},
        activity_type := #{name := ActivityType},
        activity_id := ActivityId,
        scheduled_time := ScheduledTime,
        current_attempt_scheduled_time := CurrentAttemptScheduledTime,
        started_time := StartedTime,
        attempt := Attempt
    } = Task,
    ProcLabel = temporal_sdk_utils_path:string_path([
        ?MODULE,
        Cluster,
        WorkflowNamespace,
        Namespace,
        TaskQueue,
        WorkflowType,
        ActivityType,
        ActivityId
    ]),
    proc_lib:set_label(ProcLabel),
    temporal_sdk_limiter:inc(LimiterCounters),

    {UserHeaderData, SDKHeader} =
        temporal_sdk_api_header:get_sdk(
            #{}, Task, 'temporal.api.workflowservice.v1.PollActivityTaskQueueResponse', ApiContext
        ),
    OtelCtx =
        case SDKHeader of
            #{otel_context := OC} -> OC;
            #{} -> otel_ctx:new()
        end,

    SD = #state{
        %% --------------- input
        api_ctx = ApiContext,
        task = Task,
        execution_module = ExecutionModule,
        %% --------------- task
        data = TaskSettingsData,
        last_heartbeat = TaskSettingsLastHeartbeat,
        task_timeout = fetch_task_timeout(WorkerOpts, Task),
        heartbeat_timeout = fetch_heartbeat_timeout(WorkerOpts, Task),
        %% cancel_requested = false
        %% activity_paused = false
        %% task_result = []
        %% closed_state = error
        task_user_data = UserHeaderData,
        %% --------------- executor
        workflow_executor_pid = WorkflowExecutorPid,
        proc_label = ProcLabel,
        %% stop_reason = normal
        %% execution_pid = undefined
        %% awaiter = undefined
        %% await_pattern = undefined
        %% handle_heartbeat_pid = undefined
        %% handle_heartbeat_ref = undefined
        %% handle_cancel_pid = undefined
        %% --------------- telemetry
        %% started_at = 0
        otel_ctx = OtelCtx,
        ev_metadata = #{
            cluster => Cluster,
            worker_id => WorkerId,
            namespace => Namespace,
            workflow_namespace => WorkflowNamespace,
            task_queue => TaskQueue,
            workflow_type => WorkflowType,
            activity_type => ActivityType,
            activity_id => ActivityId,

            worker_identity => WorkerIdentity,
            execution_module => ExecutionModule,

            attempt => Attempt,
            scheduled_time => temporal_sdk_utils_time:protobuf_to_nanos(ScheduledTime),
            current_attempt_scheduled_time => temporal_sdk_utils_time:protobuf_to_nanos(
                CurrentAttemptScheduledTime
            ),
            started_time => temporal_sdk_utils_time:protobuf_to_nanos(StartedTime)
        }
    },
    T = ?EV(SD, [executor, start]),
    ?EV(SD, [task, start]),
    StateData = SD#state{started_at = T},
    {ok, execute, StateData}.

terminate(Reason, _State, StateData) ->
    #state{
        api_ctx = #{limiter_counters := [LimiterCounters]},
        execution_module = ExecutionMod,
        ev_metadata = EvMetadata,
        started_at = StartedAt,
        stop_reason = StopReason,
        closed_state = ClosedState
    } = StateData,
    SD = cleanup(StateData#state{ev_metadata = EvMetadata#{closed_state => ClosedState}}),
    temporal_sdk_limiter:dec(LimiterCounters),
    case erlang:function_exported(ExecutionMod, terminate, 1) of
        true -> spawn(ExecutionMod, terminate, [build_handler_context(StateData)]);
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
        {{timeout, heartbeat}, StateData#state.heartbeat_timeout, heartbeat},
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
    handle_close_enter(?FUNCTION_NAME, StateData);
complete_task(EventType, EventContent, StateData) ->
    handle_close_common(?FUNCTION_NAME, EventType, EventContent, StateData).

cancel_task(enter, State, StateData) when State =:= execute; State =:= await_data ->
    handle_close_enter(?FUNCTION_NAME, StateData);
cancel_task(EventType, EventContent, StateData) ->
    handle_close_common(?FUNCTION_NAME, EventType, EventContent, StateData).

fail_task(enter, State, StateData) when State =:= execute; State =:= await_data ->
    handle_close_enter(?FUNCTION_NAME, StateData);
fail_task(EventType, EventContent, StateData) ->
    handle_close_common(?FUNCTION_NAME, EventType, EventContent, StateData).

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
    #state{api_ctx = ApiCtx, last_heartbeat = LH} = StateData,
    case temporal_sdk_api_activity:respond_activity_task_failed(ApiCtx, LH, AppFailure) of
        ok ->
            {stop, normal, StateData#state{closed_state = failed}};
        Err ->
            {stop, normal, StateData#state{
                stop_reason = {error, Err, ?EVST}, closed_state = error
            }}
    end;
handle_api_call(_From, {fail, Class, Reason, Stacktrace}, StateData) ->
    {next_state, fail_task, StateData#state{
        stop_reason = {Class, Reason, Stacktrace}, closed_state = failed
    }};
handle_api_call(From, {cancel_requested}, StateData) ->
    {keep_state_and_data, {reply, From, StateData#state.cancel_requested}};
handle_api_call(From, {activity_paused}, StateData) ->
    {keep_state_and_data, {reply, From, StateData#state.activity_paused}};
handle_api_call(From, {elapsed_time}, StateData) ->
    {keep_state_and_data, {reply, From, elapsed_time(StateData)}};
handle_api_call(From, {remaining_time}, StateData) ->
    {keep_state_and_data, {reply, From, remaining_time(StateData)}};
handle_api_call(From, {get_data}, StateData) ->
    {keep_state_and_data, {reply, From, StateData#state.data}};
handle_api_call(From, {last_heartbeat}, StateData) ->
    {keep_state_and_data, {reply, From, StateData#state.last_heartbeat}}.

handle_api_cast({heartbeat}, _StateData) ->
    {keep_state_and_data, {{timeout, heartbeat}, 0, heartbeat}};
handle_api_cast({heartbeat, Heartbeat}, StateData) ->
    {keep_state, StateData#state{last_heartbeat = Heartbeat}, {{timeout, heartbeat}, 0, heartbeat}};
handle_api_cast({set_data, Data}, StateData) ->
    {keep_state, StateData#state{data = Data}}.

%% -------------------------------------------------------------------------------------------------
%% handle_common heartbeat handler
handle_common(
    State,
    cast,
    {?MSG_PRV, {heartbeat_result, Result}},
    #state{handle_heartbeat_ref = undefined} = StateData
) when State =:= execute; State =:= await_data ->
    case Result of
        heartbeat ->
            record_heartbeat(StateData);
        {heartbeat, H} ->
            record_heartbeat(StateData#state{last_heartbeat = H});
        {complete, R} ->
            {next_state, complete_task, StateData#state{task_result = R}};
        {cancel, D} ->
            {next_state, cancel_task, StateData#state{task_result = D}};
        {fail, E} ->
            {next_state, fail_task, StateData#state{stop_reason = E, closed_state = failed}}
    end;
handle_common(
    State,
    cast,
    {?MSG_PRV, {heartbeat_error, Error}},
    #state{handle_heartbeat_ref = undefined} = StateData
) when State =:= execute; State =:= await_data ->
    {next_state, fail_task, StateData#state{stop_reason = Error}};
handle_common(
    State,
    cast,
    {?MSG_PRV, {Action, _ResultOrError}},
    StateData
) when
    (State =:= execute orelse State =:= await_data) andalso
        (Action =:= heartbeat_result orelse Action =:= heartbeat_error)
->
    {next_state, fail_task, StateData#state{
        stop_reason = {error, "RecordActivityTaskHeartbeatRequest timeout.", ?EVST}
    }};
%% -------------------------------------------------------------------------------------------------
%% handle_common cancel handler
handle_common(
    State,
    cast,
    {?MSG_PRV, {cancel_result, Result}},
    StateData
) when State =:= execute; State =:= await_data ->
    case Result of
        ignore ->
            keep_state_and_data;
        {complete, R} ->
            {next_state, complete_task, StateData#state{task_result = R}};
        {cancel, D} ->
            {next_state, cancel_task, StateData#state{task_result = D}};
        {fail, E} ->
            {next_state, fail_task, StateData#state{stop_reason = E, closed_state = failed}}
    end;
handle_common(
    State,
    cast,
    {?MSG_PRV, {cancel_error, Error}},
    #state{handle_heartbeat_ref = undefined} = StateData
) when State =:= execute; State =:= await_data ->
    {next_state, fail_task, StateData#state{stop_reason = Error}};
%% -------------------------------------------------------------------------------------------------
%% handle_common heartbeat gRPC response
handle_common(
    State,
    info,
    {?TEMPORAL_SDK_GRPC_TAG, Ref, {ok, #{cancel_requested := CR, activity_paused := AP}}},
    #state{handle_heartbeat_ref = Ref, handle_cancel_pid = undefined} = StateData
) when State =:= execute; State =:= await_data ->
    SD = StateData#state{
        cancel_requested = CR orelse StateData#state.cancel_requested,
        activity_paused = AP,
        handle_heartbeat_ref = undefined
    },
    Pid = spawn_handler(SD, handle_cancel, cancel_result, cancel_error),
    {keep_state, SD#state{handle_cancel_pid = Pid}};
handle_common(
    State,
    info,
    {?TEMPORAL_SDK_GRPC_TAG, Ref, Error},
    #state{handle_heartbeat_ref = Ref, handle_cancel_pid = undefined} = StateData
) when State =:= execute; State =:= await_data ->
    {next_state, fail_task, StateData#state{stop_reason = {error, Error, ?EVST}}};
handle_common(
    State,
    info,
    {?TEMPORAL_SDK_GRPC_TAG, Ref, _ResultOrError},
    #state{handle_heartbeat_ref = Ref} = StateData
) when State =:= execute; State =:= await_data ->
    {next_state, fail_task, StateData#state{
        stop_reason = {error, "handle_cancel/1 callback timeout.", ?EVST}
    }};
%% -------------------------------------------------------------------------------------------------
%% handle_common heartbeat timeout
handle_common(
    State,
    {timeout, heartbeat},
    heartbeat,
    #state{handle_heartbeat_pid = undefined} = StateData
) when State =:= execute; State =:= await_data ->
    Pid = spawn_handler(StateData, handle_heartbeat, heartbeat_result, heartbeat_error),
    {keep_state, StateData#state{handle_heartbeat_pid = Pid}, {
        {timeout, heartbeat}, StateData#state.heartbeat_timeout, heartbeat
    }};
handle_common(
    State,
    {timeout, heartbeat},
    heartbeat,
    StateData
) when State =:= execute; State =:= await_data ->
    {stop, normal, StateData#state{
        stop_reason = {error, "handle_heartbeat/1 callback timeout.", ?EVST}
    }};
%% -------------------------------------------------------------------------------------------------
%% handle_common OTP message
handle_common(State, info, {?TEMPORAL_SDK_OTP_TAG, Message}, StateData) when
    State =:= execute; State =:= await_data
->
    #state{execution_module = ExecutionModule} = StateData,
    Context = build_handler_context(StateData),
    try
        case ExecutionModule:handle_message(Context, Message) of
            ignore ->
                keep_state_and_data;
            {complete, R} ->
                {next_state, complete_task, StateData#state{task_result = R}};
            {cancel, D} ->
                {next_state, cancel_task, StateData#state{task_result = D}};
            {fail, E} ->
                {next_state, fail_task, StateData#state{stop_reason = E, closed_state = failed}};
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
%% handle_common direct execution activity task_token message
handle_common(State, cast, {?MSG_PRV, task_token, Token}, StateData) when
    State =:= execute; State =:= await_data
->
    AC = temporal_sdk_api_context:update(StateData#state.api_ctx, #{task_token => Token}),
    {keep_state, StateData#state{api_ctx = AC}, {
        {timeout, heartbeat}, StateData#state.heartbeat_timeout, heartbeat
    }};
handle_common(_State, cast, {?MSG_PRV, direct_cancel_request}, StateData) ->
    {stop, normal, StateData#state{closed_state = direct_canceled}};
%% -------------------------------------------------------------------------------------------------
%% handle_common task timeout
handle_common(_State, {timeout, task}, Pid, #state{execution_pid = Pid} = StateData) ->
    #state{
        api_ctx = #{
            worker_opts := #{
                task_settings := #{
                    start_to_close_timeout_ratio := StRatio,
                    schedule_to_close_timeout_ratio := SchRatio
                }
            }
        },
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
                    start_to_close_timeout => temporal_sdk_api_activity_task:start_to_close_timeout(
                        Task
                    ),
                    start_to_close_timeout_ratio => StRatio,
                    schedule_to_close_timeout => temporal_sdk_api_activity_task:schedule_to_close_timeout(
                        Task
                    ),
                    schedule_to_close_timeout_ratio => SchRatio
                }},
                ?EVST}
    },
    {next_state, fail_task, SD};
%% -------------------------------------------------------------------------------------------------
%% handle_common exits
handle_common(_State, info, {'EXIT', Pid, normal}, #state{execution_pid = Pid} = StateData) ->
    {keep_state, StateData#state{execution_pid = undefined}};
handle_common(_State, info, {'EXIT', Pid, normal}, #state{handle_heartbeat_pid = Pid} = StateData) ->
    {keep_state, StateData#state{handle_heartbeat_pid = undefined}};
handle_common(_State, info, {'EXIT', Pid, normal}, #state{handle_cancel_pid = Pid} = StateData) ->
    {keep_state, StateData#state{handle_cancel_pid = undefined}};
handle_common(_State, info, {'EXIT', Pid, normal}, #state{workflow_executor_pid = Pid} = StateData) ->
    #state{api_ctx = #{task_opts := #{token := Token}}} = StateData,
    case Token of
        undefined ->
            {stop, normal, StateData#state{
                stop_reason =
                    {error,
                        "Unexpected workflow executor process exit when running direct execution activity.",
                        ?EVST}
            }};
        _ ->
            {keep_state, StateData#state{workflow_executor_pid = undefined}}
    end;
handle_common(_State, info, {'EXIT', Pid, _Reason}, #state{execution_pid = Pid}) ->
    keep_state_and_data;
handle_common(_State, info, {'EXIT', _Pid, ?LINKED_PID_EXIT_REASON}, _StateData) ->
    keep_state_and_data;
handle_common(_State, info, {'EXIT', _Pid, normal}, _StateData) ->
    keep_state_and_data;
handle_common(_State, info, {'EXIT', Pid, Reason}, StateData) ->
    {next_state, fail_task, StateData#state{
        stop_reason =
            {error, #{reason => "Linked process abnormal exit.", pid => Pid, exit_reason => Reason},
                ?EVST}
    }};
%% -------------------------------------------------------------------------------------------------
%% handle_common workflow_execution_terminated
handle_common(
    _State,
    cast,
    {?MSG_PRV, workflow_execution_terminated},
    #state{api_ctx = #{task_opts := #{token := undefined}}} = StateData
) ->
    {stop, normal, StateData#state{closed_state = direct_exit}};
handle_common(_State, cast, {?MSG_PRV, workflow_execution_terminated}, _StateData) ->
    keep_state_and_data;
%% -------------------------------------------------------------------------------------------------
%% handle_common unhandled message
handle_common(State, EventType, EventContent, StateData) ->
    {stop, normal, StateData#state{
        stop_reason =
            {error,
                #{
                    reason => "Unhandled event received by executor.",
                    state => State,
                    event => EventType,
                    event_content => EventContent
                },
                ?EVST}
    }}.

record_heartbeat(#state{api_ctx = #{task_opts := #{token := undefined}}}) ->
    keep_state_and_data;
record_heartbeat(StateData) ->
    #state{api_ctx = ApiCtx, last_heartbeat = LastHeartbeat} = StateData,
    case temporal_sdk_api_activity:record_activity_task_heartbeat(ApiCtx, LastHeartbeat) of
        Ref when is_reference(Ref) -> {keep_state, StateData#state{handle_heartbeat_ref = Ref}};
        Err -> {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end.

%% -------------------------------------------------------------------------------------------------
%% handle_close

handle_close_enter(State, StateData) ->
    #state{
        api_ctx = #{task_opts := #{token := Token} = TaskOpts},
        task_result = TaskResult,
        workflow_executor_pid = WorkflowExecutorPid,
        stop_reason = StopReason
    } = StateData,
    case Token of
        undefined ->
            IndexKey = map_get(index_key, TaskOpts),
            {MsgTag, MsgResult} =
                case State of
                    complete_task -> {completed, TaskResult};
                    fail_task -> {failed, StopReason}
                end,
            gen_statem:cast(
                WorkflowExecutorPid, {?MSG_PRV, direct_execution, MsgTag, IndexKey, MsgResult}
            ),
            {keep_state, cleanup(StateData), {{timeout, heartbeat}, cancel}};
        _ ->
            handle_close(State, StateData)
    end.

handle_close_common(State, cast, {?MSG_PRV, task_token, Token}, StateData) ->
    #state{api_ctx = ApiCtx} = StateData,
    AC = temporal_sdk_api_context:update(ApiCtx, #{task_token => Token}),
    handle_close(State, StateData#state{api_ctx = AC});
handle_close_common(State, EventType, EventContent, StateData) ->
    handle_common(State, EventType, EventContent, StateData).

handle_close(complete_task, StateData) ->
    #state{api_ctx = ApiCtx, task_result = TaskResult} = StateData,
    temporal_sdk_api_activity:respond_activity_task_completed(ApiCtx, TaskResult),
    {stop, normal, StateData#state{closed_state = completed}};
handle_close(cancel_task, StateData) ->
    #state{api_ctx = ApiCtx, task_result = Details} = StateData,
    temporal_sdk_api_activity:respond_activity_task_canceled(ApiCtx, Details),
    {stop, normal, StateData#state{closed_state = canceled}};
handle_close(fail_task, StateData) ->
    #state{api_ctx = ApiCtx, last_heartbeat = LH} = StateData,
    AF = do_handle_fail_task(StateData),
    case temporal_sdk_api_activity:respond_activity_task_failed(ApiCtx, LH, AF) of
        ok ->
            {stop, normal, StateData};
        Err ->
            {stop, normal, StateData#state{
                stop_reason = {error, Err, ?EVST}, closed_state = error
            }}
    end.

% FIXME: refactor blocking handle_failure/4 call to safe & async spawn handler
do_handle_fail_task(StateData) ->
    #state{stop_reason = {C, R, S}, execution_module = Mod} = StateData,
    Context = build_handler_context(StateData),
    case erlang:function_exported(Mod, handle_failure, 3) of
        true -> Mod:handle_failure(Context, C, R, S);
        false -> #{source => C, message => R, stack_trace => S}
    end.

%% -------------------------------------------------------------------------------------------------
%% spawn helpers

spawn_execution(StateData) ->
    #state{
        api_ctx = ApiCtx,
        task = Task,
        execution_module = ExecutionModule,
        otel_ctx = OtelCtx,
        proc_label = ProcLabel
    } = StateData,
    ExecutorPid = self(),
    ExecutionProcLabel = temporal_sdk_utils_path:string_path([ProcLabel, execution]),
    Context = build_context(StateData),
    Input = temporal_sdk_api_activity_task:input(ApiCtx, Task),
    T = ?EV(StateData, [execution, start]),
    spawn_link(fun() ->
        proc_lib:set_label(ExecutionProcLabel),
        temporal_sdk_executor:set_executor_dict(ExecutorPid),
        otel_ctx:attach(OtelCtx),
        % TODO start new otel span
        try
            Result = ExecutionModule:execute(Context, Input),
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

spawn_handler(StateData, HandlerFun, ResultTag, ErrorTag) ->
    #state{execution_module = ExecutionModule} = StateData,
    ExecutorPid = self(),
    Context = build_handler_context(StateData),
    spawn_link(fun() ->
        try
            Result = ExecutionModule:HandlerFun(Context),
            gen_statem:cast(ExecutorPid, {?MSG_PRV, {ResultTag, Result}})
        catch
            Class:Reason:Stacktrace ->
                gen_statem:cast(
                    ExecutorPid, {?MSG_PRV, {ErrorTag, {Class, Reason, Stacktrace}}}
                ),
                erlang:raise(Class, Reason, Stacktrace)
        end
    end).

%% -------------------------------------------------------------------------------------------------
%% state helpers

-spec build_context(StateData :: state()) -> temporal_sdk_activity:context().
build_context(StateData) ->
    #state{api_ctx = #{cluster := Cluster, worker_opts := WO}, task_user_data = TUD} = StateData,
    TUD#{
        cluster => Cluster,
        executor_pid => self(),
        otel_ctx => StateData#state.otel_ctx,
        task => StateData#state.task,
        worker_opts => WO,
        started_at => StateData#state.started_at,
        task_timeout => StateData#state.task_timeout
    }.

-spec build_handler_context(StateData :: state()) -> temporal_sdk_activity:handler_context().
build_handler_context(StateData) ->
    #{
        data => StateData#state.data,
        cancel_requested => StateData#state.cancel_requested,
        activity_paused => StateData#state.activity_paused,
        last_heartbeat => StateData#state.last_heartbeat,
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
    SD2 =
        case StateData#state.handle_heartbeat_pid of
            undefined ->
                SD1;
            Pid2 ->
                exit(Pid2, ?LINKED_PID_EXIT_REASON),
                SD1#state{handle_heartbeat_pid = undefined}
        end,
    case StateData#state.handle_cancel_pid of
        undefined ->
            SD2;
        Pid3 ->
            exit(Pid3, ?LINKED_PID_EXIT_REASON),
            SD2#state{handle_cancel_pid = undefined}
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

fetch_task_timeout(WorkerOpts, Task) ->
    min(
        get_task_start_to_close_timeout(WorkerOpts, Task),
        get_task_schedule_to_close_timeout(WorkerOpts, Task)
    ).

fetch_heartbeat_timeout(#{task_settings := #{heartbeat_timeout_ratio := Ratio}}, Task) ->
    case temporal_sdk_api_activity_task:heartbeat_timeout(Task) of
        T when is_integer(T), T > 0 -> round(T * Ratio);
        _ -> infinity
    end.

get_task_start_to_close_timeout(
    #{task_settings := #{start_to_close_timeout_ratio := Ratio}}, Task
) ->
    case temporal_sdk_api_activity_task:start_to_close_timeout(Task) of
        T when is_integer(T), T > 0 -> round(T * Ratio);
        _ -> infinity
    end.

get_task_schedule_to_close_timeout(
    #{task_settings := #{schedule_to_close_timeout_ratio := Ratio}}, Task
) ->
    case temporal_sdk_api_activity_task:schedule_to_close_timeout(Task) of
        T when is_integer(T), T > 0 -> round(T * Ratio);
        _ -> infinity
    end.

%% -------------------------------------------------------------------------------------------------
%% telemetry

ev_origin() -> ?EVENT_ORIGIN.

ev_metadata(StateData) ->
    maps:merge(StateData#state.ev_metadata, build_handler_context(StateData)).
