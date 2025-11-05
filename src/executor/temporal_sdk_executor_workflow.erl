-module(temporal_sdk_executor_workflow).
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
    start_scope/3,
    execute/3,
    replay/3,
    complete_task/3,
    poll/3,
    fail_task/3,
    query_closed/3
]).

-include("temporal_sdk_executor.hrl").
-include("sdk.hrl").
-include("proto.hrl").
-include("telemetry.hrl").

-define(EVENT_ORIGIN, workflow).

-define(LINKED_PID_EXIT_REASON, workflow_execution_terminated).

-type execution_state() ::
    started
    | {completed, Result :: temporal_sdk:term_to_payloads()}
    | {canceled, Details :: temporal_sdk:term_to_payloads()}
    | {failed,
        Failure ::
            temporal_sdk:application_failure()
            | temporal_sdk:user_application_failure()}
    | {continued_as_new, #{
        task_queue := unicode:chardata(), workflow_type := unicode:chardata()
    }}
    | error
    | queried
    | mutated
    | duplicate
    | stale.
-export_type([execution_state/0]).

%% -------------------------------------------------------------------------------------------------
%% state record

-define(INITIAL_WORKFLOW_INFO, #{
    event_id => 1,
    open_executions_count => 1,
    open_tasks_count => 0,
    suggest_continue_as_new => false,
    history_size_bytes => 0,
    otp_messages_count => #{received => 0, recorded => 0, ignored => 0}
}).

-record(state, {
    %% --------------- input
    api_ctx :: temporal_sdk_api:context(),
    api_ctx_activity :: temporal_sdk_api:context(),
    caller_pid :: pid() | undefined,
    %% --------------- task
    task_attempt = 1 :: pos_integer(),
    task_input :: temporal_sdk:term_from_payloads(),
    task_previous_started_event_id :: pos_integer(),
    task_started_event_id :: pos_integer(),
    task_workflow_execution :: ?TEMPORAL_SPEC:'temporal.api.common.v1.WorkflowExecution'(),
    run_timeout :: erlang:timeout(),
    task_timeout :: erlang:timeout(),
    event_id = 1 :: pos_integer(),
    is_replaying :: boolean(),
    workflow_info :: temporal_sdk_workflow:workflow_info(),
    workflow_result = [] :: temporal_sdk:term_to_payloads(),
    %% --------------- executions
    execution_module :: module(),
    execution_state = started :: execution_state(),
    executions_awaits = [] :: [gen_statem:from() | {awaited, gen_statem:from()}],
    workflow_context :: temporal_sdk_workflow:context(),
    executions_commands = [] :: [
        {
            pos_integer(),
            [
                temporal_sdk_workflow:index_command()
                | {pid(), temporal_sdk_workflow:index_command()}
            ],
            [temporal_sdk_workflow:awaitable_index()]
        }
    ],
    replayed_commands = [] :: [temporal_sdk_workflow:awaitable_index()],
    commands = [] :: [
        temporal_sdk_workflow:index_command() | {pid(), temporal_sdk_workflow:index_command()}
    ],
    pending_commands = [] :: [temporal_sdk_workflow:index_command()],
    completed_commands = [] :: [temporal_sdk_workflow:index_command()],
    %% --------------- executor
    proc_label :: string(),
    stop_reason = normal ::
        normal | temporal_sdk_telemetry:exception() | [temporal_sdk_telemetry:exception()],
    linked_pids = [] :: [pid()],
    direct_execution_pids = [] :: [{temporal_sdk_workflow:activity(), pid()}],
    open_executions_count = 0 :: non_neg_integer(),
    total_executions_count = 0 :: non_neg_integer(),
    open_tasks_count = 0 :: non_neg_integer(),
    open_locals_count = 0 :: non_neg_integer(),
    has_upserted_events = false :: boolean(),
    has_replayed_events = false :: boolean(),
    await_open_before_close = true :: boolean(),
    otp_messages_count :: #{
        received := {Current :: non_neg_integer(), Maximum :: pos_integer() | infinity},
        recorded => {Current :: non_neg_integer(), Maximum :: pos_integer() | infinity},
        ignored => {Current :: non_neg_integer(), Maximum :: pos_integer() | infinity}
    },
    history_events = [] :: [temporal_sdk_workflow:history_event()],
    queries = #{} :: #{
        unicode:chardata() => ?TEMPORAL_SPEC:'temporal.api.query.v1.WorkflowQueryResult'()
    },
    messages = [] :: [?TEMPORAL_SPEC:'temporal.api.protocol.v1.Message'()],
    history_table = undefined :: ets:table() | undefined,
    index_table = undefined :: ets:table() | undefined,
    blocking_awaitable = false ::
        {temporal_sdk_workflow:activity_index_key(), temporal_sdk_workflow:activity_data()}
        | false,
    grpc_req_ref = undefined ::
        undefined
        | regular_queue
        | {poll, reference()}
        | {get_history, reference()}
        | {get_history_reverse, reference()}
        | {complete_task, reference()},
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
    Task :: temporal_sdk_workflow:task(),
    CallerPid :: pid() | undefined
) -> {ok, pid()} | {error, term()}.
start(ApiContext, Task, CallerPid) ->
    case gen_statem:start(?MODULE, [ApiContext, Task, CallerPid], []) of
        ignore -> {error, "Workflow executor start ignored."};
        Ret -> Ret
    end.

init([ApiContext, Task, CallerPid]) ->
    process_flag(trap_exit, true),

    #{
        cluster := Cluster,
        worker_opts := #{
            worker_id := WorkerId,
            namespace := Namespace,
            task_queue := TaskQueue,
            task_settings := #{
                otp_messages_limits := OtpMessagesLimits,
                await_open_before_close := AwaitOpenBeforeClose
            }
        } =
            WorkerOpts,
        worker_identity := WorkerIdentity,
        limiter_counters := [WorkflowLC, _EagerLC, _DirectLC],
        execution_module := ExecutionModule
    } = ApiContext,
    #{
        workflow_execution := #{workflow_id := WorkflowId, run_id := RunId} = WorkflowExecution,
        workflow_type := #{name := WorkflowType},
        previous_started_event_id := PreviousStartedEventId,
        started_event_id := StartedEventId,
        attempt := Attempt,
        history := #{events := TemporalHistoryEvents}
    } = Task,
    ScheduledTime =
        case Task of
            #{scheduled_time := SchTi} -> temporal_sdk_utils_time:protobuf_to_nanos(SchTi);
            #{} -> 0
        end,
    StartedTime =
        case Task of
            #{started_time := StTi} -> temporal_sdk_utils_time:protobuf_to_nanos(StTi);
            #{} -> 0
        end,

    ProcLabel = temporal_sdk_utils_path:string_path([
        ?MODULE, Cluster, Namespace, TaskQueue, WorkflowType, WorkflowId, RunId
    ]),
    proc_lib:set_label(ProcLabel),
    temporal_sdk_limiter:inc(WorkflowLC),

    STask = temporal_sdk_api_workflow_task:workflow_execution_started_event_attributes(Task),
    {UserHeaderData, SDKHeader} =
        temporal_sdk_api_header:get_sdk(
            #{}, STask, 'temporal.api.workflowservice.v1.PollWorkflowTaskQueueResponse', ApiContext
        ),
    OtelCtx =
        case SDKHeader of
            #{otel_context := OC} -> OC;
            #{} -> otel_ctx:new()
        end,

    IsReplaying = PreviousStartedEventId > 0 orelse StartedEventId > 3,

    WI = maps:merge(
        temporal_sdk_api_workflow_task:build_context_workflow_info(ApiContext, Task),
        UserHeaderData
    ),

    WorkflowContext = #{
        execution_id => undefined,
        cluster => Cluster,
        executor_pid => self(),
        otel_ctx => OtelCtx,
        worker_opts => WorkerOpts,
        history_table => undefined,
        index_table => undefined,
        workflow_info => WI,
        task => maps:without([history], Task),
        attempt => Attempt,
        is_replaying => IsReplaying
    },

    RunTimeout = fetch_run_timeout(WorkerOpts, Task),
    TaskTimeout = fetch_task_timeout(WorkerOpts, Task),

    SD = #state{
        %% --------------- input
        api_ctx = ApiContext,
        api_ctx_activity = temporal_sdk_api_context:activity_from_workflow(ApiContext),
        caller_pid = CallerPid,
        %% --------------- task
        task_attempt = Attempt,
        task_input = temporal_sdk_api_workflow_task:input(ApiContext, Task),
        task_previous_started_event_id = PreviousStartedEventId,
        task_started_event_id = StartedEventId,
        task_workflow_execution = WorkflowExecution,
        run_timeout = RunTimeout,
        task_timeout = TaskTimeout,
        %% event_id = 1
        is_replaying = IsReplaying,
        workflow_info = maps:merge(?INITIAL_WORKFLOW_INFO, #{
            attempt => Attempt, is_replaying => IsReplaying
        }),
        %% workflow_result = []
        %% --------------- executions
        execution_module = ExecutionModule,
        %% execution_state = started
        %% executions_awaits = []
        workflow_context = WorkflowContext,
        %% executions_commands = []
        %% replayed_commands = []
        %% commands = []
        %% pending_commands = []
        %% completed_commands = []
        %% --------------- executor
        proc_label = ProcLabel,
        %% stop_reason = normal
        %% linked_pids = []
        %% direct_execution_pids = []
        %% open_executions_count = 0
        %% total_executions_count = 0
        %% open_tasks_count = 0
        %% open_locals_count = 0
        %% has_upserted_events = false
        %% has_replayed_events = false
        await_open_before_close = AwaitOpenBeforeClose,
        otp_messages_count = #{
            received => {0, proplists:get_value(received, OtpMessagesLimits, infinity)},
            recorded => {0, proplists:get_value(recorded, OtpMessagesLimits, 1_000)},
            ignored => {0, proplists:get_value(ignored, OtpMessagesLimits, infinity)}
        },
        %% history_events = []
        %% queries = #{}
        %% messages = []
        %% history_table = undefined
        %% index_table = undefined
        %% blocking_awaitable = false
        %% grpc_req_ref = undefined
        %% --------------- telemetry
        %% started_at = 0
        otel_ctx = OtelCtx,
        ev_metadata = #{
            cluster => Cluster,
            worker_id => WorkerId,
            namespace => Namespace,
            task_queue => TaskQueue,
            workflow_type => WorkflowType,
            workflow_id => WorkflowId,
            workflow_run_id => RunId,

            worker_identity => WorkerIdentity,
            execution_module => ExecutionModule,

            scheduled_time => ScheduledTime,
            started_time => StartedTime,

            executor_pid => self()
        }
    },
    T = ?EV(SD, [executor, start]),
    ?EV(SD, [task, start]),
    SD1 = SD#state{started_at = T},
    TActions = [
        {{timeout, run_timeout}, RunTimeout, timeout},
        {{timeout, task_timeout}, TaskTimeout, timeout}
    ],
    case
        temporal_sdk_api_awaitable_history_table:append(
            regular, 1, [], TemporalHistoryEvents, undefined
        )
    of
        {ok, HE} ->
            SD2 = SD1#state{history_events = HE},
            case Task of
                #{scheduled_time := _, started_time := _} -> {ok, start_scope, SD2, TActions};
                #{} -> {ok, query_closed, SD2, TActions}
            end;
        Err ->
            {ok, fail_task, SD1#state{stop_reason = {error, Err, ?EVST}}}
    end.

terminate(Reason, _State, StateData) ->
    cleanup(StateData),
    #state{
        api_ctx = #{limiter_counters := [WorkflowLC, _EagerLC, _DirectLC]} = ApiCtx,
        caller_pid = CallerPid,
        ev_metadata = EvMetadata,
        started_at = StartedAt,
        execution_state = ExecutionState,
        stop_reason = StopReason
    } =
        StateData,
    temporal_sdk_limiter:dec(WorkflowLC),
    case CallerPid of
        undefined -> temporal_sdk_api_poll:shutdown_worker(ApiCtx);
        _ -> ok
    end,

    CState =
        case ExecutionState of
            {ES, _} -> ES;
            started -> error;
            Err -> Err
        end,
    SD = StateData#state{ev_metadata = EvMetadata#{closing_state => CState}},
    case StopReason of
        normal ->
            ?EV(SD, [task, stop], StartedAt);
        {_, #{execution_id := EId}, St} ->
            ?EV(
                SD,
                [task, exception],
                StartedAt,
                {error, {execution_error, EId}, St}
            );
        _ ->
            ?EV(SD, [task, exception], StartedAt, StopReason)
    end,
    case Reason of
        normal -> ?EV(SD, [executor, stop], StartedAt);
        R -> ?EV(SD, [executor, exception], StartedAt, {error, R, ?EVST})
    end.

callback_mode() -> [state_functions, state_enter].

%% -------------------------------------------------------------------------------------------------
%% gen_statem state callbacks

start_scope(enter, start_scope, StateData) ->
    handle_start_scope_enter(StateData);
start_scope(info, {?MSG_PRV, {recycled_integer, Int}}, StateData) ->
    handle_start_scope(Int, StateData);
start_scope(EventType, EventContent, StateData) ->
    handle_common(?FUNCTION_NAME, EventType, EventContent, StateData).

execute(enter, start_scope, StateData) ->
    case spawn_main_execution(StateData) of
        {ok, SD} ->
            {keep_state, SD#state{task_input = []}};
        Err ->
            gen_statem:cast(self(), fail_task),
            {keep_state, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end;
execute(enter, replay, _StateData) ->
    keep_state_and_data;
execute({call, From}, {?MSG_API, ExecutionId, Command}, StateData) ->
    handle_execute_api_call(From, ExecutionId, Command, StateData);
execute(cast, {?MSG_API, ExecutionId, Command}, StateData) ->
    handle_execute_api_cast(ExecutionId, Command, StateData);
execute(cast, {?MSG_PRV, {execution, State, ExecutionId, Result}}, StateData) ->
    handle_execute_result(State, ExecutionId, Result, StateData);
execute(EventType, EventContent, StateData) ->
    handle_common(?FUNCTION_NAME, EventType, EventContent, StateData).

replay(enter, State, _StateData) when State =:= execute; State =:= complete_task; State =:= poll ->
    keep_state_and_data;
replay(internal, handle_replay, StateData) ->
    handle_replay(StateData);
replay(EventType, EventContent, StateData) ->
    handle_common(?FUNCTION_NAME, EventType, EventContent, StateData).

complete_task(enter, State, StateData) when State =:= replay; State =:= complete_task ->
    handle_complete_task_enter(StateData);
complete_task(
    info, {?TEMPORAL_SDK_GRPC_TAG, Ref, Response}, #state{grpc_req_ref = {complete_task, Ref}} = SD
) ->
    handle_complete_task(Response, SD);
complete_task(EventType, EventContent, StateData) ->
    handle_common(?FUNCTION_NAME, EventType, EventContent, StateData).

poll(enter, State, StateData) when State =:= replay; State =:= complete_task; State =:= poll ->
    handle_poll_enter(StateData);
poll(EventType, EventContent, StateData) ->
    handle_poll(EventType, EventContent, StateData).

fail_task(enter, _State, StateData) ->
    handle_fail_task(StateData).

query_closed(enter, query_closed, StateData) ->
    handle_query_closed(StateData).

%% -------------------------------------------------------------------------------------------------
%% state handlers

handle_start_scope_enter(StateData) ->
    #state{api_ctx = ApiCtx0} = StateData,
    temporal_sdk_scope:start(ApiCtx0),
    {NextPageToken, ApiCtx} = temporal_sdk_api_context:take_next_page_token(ApiCtx0),
    case maybe_get_workflow_execution_history(NextPageToken, StateData#state{api_ctx = ApiCtx}) of
        {ok, SD} ->
            {keep_state, SD};
        Err ->
            gen_statem:cast(self(), fail_task),
            {keep_state, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end.

handle_start_scope(Int, StateData) ->
    maybe
        {ok, SD} ?= start_ets(Int, StateData),
        #state{api_ctx = ApiCtx, index_table = IT, workflow_context = #{task := Task}} = SD,
        {ok, _HUE} ?= temporal_sdk_api_awaitable_index_table:upsert_polled(IT, Task, ApiCtx),
        {next_state, execute, SD}
    else
        Err -> {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end.

handle_execute_api_call(From, _ExecutionId, {await, awaited}, StateData) ->
    #state{executions_awaits = EA} = StateData,
    handle_execute_maybe_replay(StateData#state{executions_awaits = [From | EA]});
handle_execute_api_call(From, _ExecutionId, {await, {ExecutionIdx, Commands}}, StateData) ->
    #state{executions_awaits = EA} = StateData,
    case spawn_local(Commands, ExecutionIdx, StateData) of
        {ok, SD} -> handle_execute_maybe_replay(SD#state{executions_awaits = [From | EA]});
        {error, Err, SD} -> {next_state, fail_task, SD#state{stop_reason = {error, Err, ?EVST}}}
    end;
handle_execute_api_call(From, _ExecutionId, workflow_info, StateData) ->
    {keep_state_and_data, {reply, From, get_workflow_info(StateData)}};
handle_execute_api_call(From, _ExecutionId, get_workflow_result, StateData) ->
    {keep_state_and_data, {reply, From, StateData#state.workflow_result}}.

handle_execute_api_cast(_ExecutionId, {set_workflow_result, WR}, StateData) ->
    {keep_state, StateData#state{workflow_result = WR}};
handle_execute_api_cast(_ExecutionId, {stop, Reason}, StateData) ->
    {stop, normal, StateData#state{stop_reason = {error, Reason, []}}};
handle_execute_api_cast(_ExecutionId, {await_open_before_close, IsEnabled}, StateData) ->
    {keep_state, StateData#state{await_open_before_close = IsEnabled}}.

handle_execute_result(completed, ExecutionIdx, Commands, StateData) ->
    #state{open_executions_count = OEC} = StateData,
    case spawn_local(Commands, ExecutionIdx, StateData#state{open_executions_count = OEC - 1}) of
        {ok, SD} -> handle_execute_maybe_replay(SD);
        {error, Err, SD} -> {next_state, fail_task, SD#state{stop_reason = {error, Err, ?EVST}}}
    end;
handle_execute_result(failed, ExecutionId, {Class, Reason, Stacktrace}, StateData) ->
    {next_state, fail_task, StateData#state{
        stop_reason = {Class, #{reason => Reason, execution_id => ExecutionId}, Stacktrace}
    }};
handle_execute_result(failed, ExecutionId, Err, StateData) ->
    {next_state, fail_task, StateData#state{
        stop_reason = {error, #{reason => Err, execution_id => ExecutionId}, ?EVST}
    }}.

handle_execute_maybe_replay(StateData) ->
    #state{executions_awaits = EA, open_executions_count = OEC} = StateData,
    case length(EA) =:= OEC of
        true -> handle_await_or_replay(StateData);
        false -> {keep_state, StateData}
    end.

handle_await_or_replay(StateData) ->
    #state{
        executions_commands = EC, commands = Cmds, replayed_commands = RCmds, execution_state = ES
    } =
        StateData,
    {_ExecutionIdxs, NCmds0, NRCmds0} = lists:unzip3(lists:keysort(1, lists:reverse(EC))),
    NCmds = lists:flatten(NCmds0),
    NRCmds = lists:flatten(NRCmds0),
    case next_event_id(StateData) of
        {ok, NEId} ->
            case do_cmds(NCmds, ES, StateData, [], NEId) of
                {ok, #state{execution_state = State} = SD, FCmds} ->
                    SD1 = SD#state{
                        commands = Cmds ++ FCmds,
                        replayed_commands = RCmds ++ NRCmds,
                        executions_commands = []
                    },
                    case State =:= started andalso NCmds =/= [] of
                        false -> {next_state, replay, SD1, {next_event, internal, handle_replay}};
                        true -> reply_and_keep_state(complete_await, SD1)
                    end;
                {error, SD} ->
                    {next_state, fail_task, SD}
            end;
        Err ->
            {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end.

handle_replay(#state{open_locals_count = OLC} = StateData) when OLC > 0 ->
    {keep_state, StateData};
handle_replay(#state{history_events = []} = StateData) ->
    replay_noevent(StateData);
handle_replay(#state{history_events = [{EId, EType, EAttr, _} | _], event_id = EId} = StateData) ->
    IsCommanded = temporal_sdk_api_command:is_event_commanded(EType, EAttr),
    replay_event(IsCommanded, StateData#state.commands, StateData);
handle_replay(#state{history_events = [Event | _], event_id = EventId} = StateData) ->
    {next_state, fail_task, StateData#state{
        stop_reason =
            {error,
                {error, #{
                    reason => "Malformed events history.",
                    received_event => Event,
                    expected_event_id => EventId
                }},
                ?EVST}
    }}.

replay_noevent(#state{grpc_req_ref = {get_history, _Ref}} = StateData) ->
    {keep_state, StateData};
replay_noevent(#state{grpc_req_ref = Ref} = StateData) when Ref /= undefined ->
    {next_state, fail_task, StateData#state{
        stop_reason =
            {error, #{reason => "Unexpected gRPC request reference.", grpc_req_ref => Ref}, ?EVST}
    }};
replay_noevent(#state{replayed_commands = RC} = StateData) when RC =/= [] ->
    #state{commands = Commands} = StateData,
    case do_rcmds(Commands, [], StateData) of
        {ok, ReAssembledCommands, SD} ->
            handle_replay(SD#state{replayed_commands = [], commands = ReAssembledCommands});
        Err ->
            {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end;
replay_noevent(#state{has_upserted_events = HUE, has_replayed_events = HRE} = StateData) when
    HUE; HRE
->
    reply(complete_await, StateData);
replay_noevent(
    #state{commands = [], open_tasks_count = 0, queries = Qs, messages = []} = StateData
) when map_size(Qs) =:= 0 ->
    reply(noevent, StateData);
replay_noevent(
    #state{api_ctx = #{task_opts := #{token := undefined}}, open_tasks_count = OTC} = StateData
) when OTC > 0 ->
    {next_state, poll, StateData};
replay_noevent(StateData) ->
    {next_state, complete_task, StateData}.

replay_event(
    true,
    [],
    #state{has_upserted_events = false, has_replayed_events = false, open_tasks_count = 0} =
        StateData
) ->
    reply(noevent, StateData);
replay_event(
    true,
    [],
    #state{has_upserted_events = false, has_replayed_events = false, blocking_awaitable = BA} =
        StateData
) when BA =/= false ->
    handle_blocking_task(StateData);
replay_event(
    true, [], #state{has_upserted_events = HUE, has_replayed_events = HRE} = StateData
) when HUE; HRE ->
    reply(complete_await, StateData);
replay_event(IsCommanded, IndexCommand, StateData) ->
    #state{
        api_ctx = ApiCtx,
        event_id = EventId,
        task_previous_started_event_id = TaskPreviousStartedEventId,
        task_started_event_id = TaskStartedEventId,
        history_events = [{_, EType, _, _} = Event | TEvents],
        open_tasks_count = OpenTasksCount,
        history_table = HistoryTable,
        index_table = IndexTable,
        workflow_info = WorkflowInfo,
        otp_messages_count = OtpMessagesCount,
        replayed_commands = ReplayedCommands
    } = StateData,
    #{worker_opts := #{task_settings := #{deterministic_check_mod := DeterministicCheckMod}}} =
        ApiCtx,
    IsReplaying =
        EventId <
            max(TaskPreviousStartedEventId, TaskStartedEventId) andalso
            (TaskPreviousStartedEventId > 0 orelse TaskStartedEventId > 3),
    maybe
        {ok, IndexCommand1} ?= update_event_id(IsCommanded, EventId, IndexCommand, StateData),
        ok ?= temporal_sdk_api_awaitable_history_table:insert_new(HistoryTable, Event),
        {ok, EventIndex} ?=
            temporal_sdk_api_awaitable_history:history_to_index(Event, HistoryTable, ApiCtx),
        {ok, ClosedTaskCount} ?=
            temporal_sdk_api_awaitable_index_table:upsert_and_count(IndexTable, EventIndex),
        {true, TIndexCommand, IC} ?=
            is_deterministic(IsCommanded, DeterministicCheckMod, EventIndex, Event, IndexCommand1),
        ignore ?= handle_mutation(IsReplaying, IC, EventIndex, HistoryTable),
        WInfo = temporal_sdk_api_awaitable_history:update_workflow_info(Event, WorkflowInfo),
        ok ?= upsert_suggest_continue_as_new(WorkflowInfo, WInfo, IndexTable, EventId),
        SD = StateData#state{
            event_id = EventId + 1,
            commands = TIndexCommand,
            history_events = TEvents,
            is_replaying = IsReplaying,
            workflow_info = WInfo,
            open_tasks_count = OpenTasksCount - ClosedTaskCount,
            otp_messages_count = update_otp_msg_count(IsReplaying, EventIndex, OtpMessagesCount),
            has_replayed_events = true,
            replayed_commands = update_rcmds(EType, ReplayedCommands, IndexCommand)
        },
        handle_replay(update_blocking_awaitable(EType, EventIndex, IC, SD))
    else
        {update_event_id_error, ESD} ->
            {next_state, fail_task, ESD};
        {mutation_reset, ResetEventId, Reason} ->
            temporal_sdk_api_workflow:reset_workflow_execution(ApiCtx, Reason, ResetEventId),
            {stop, normal, StateData#state{execution_state = mutated}};
        {mutation_fail, Err} ->
            {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}};
        {mutation_catch, Err} ->
            {next_state, fail_task, StateData#state{stop_reason = Err}};
        {error, #{reason := _, awaitable := _} = Reason} ->
            R1 = maps:without([reason], Reason),
            R2 =
                case IndexCommand of
                    [{EAw, _Cmd} | _] -> R1#{expected_awaitable => EAw};
                    _ -> R1
                end,
            {next_state, fail_task, StateData#state{
                stop_reason = {error, {nondeterministic, R2}, ?EVST}
            }};
        Err ->
            {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end.

upsert_suggest_continue_as_new(
    #{suggest_continue_as_new := false}, #{suggest_continue_as_new := true}, IndexTable, EventId
) ->
    temporal_sdk_api_awaitable_index_table:upsert_index(
        IndexTable, {{suggest_continue_as_new}, #{state => suggested, event_id => EventId}}
    );
upsert_suggest_continue_as_new(_OldWorkflowInfo, _NewWorkflowInfo, _IndexTable, _EventId) ->
    ok.

reply(Event, #state{executions_awaits = EA, execution_state = ES} = StateData) when
    length(EA) > 0, ES =:= started
->
    Replies = [{reply, From, Event} || From <- StateData#state.executions_awaits],
    {next_state, execute,
        StateData#state{
            executions_awaits = [],
            has_upserted_events = false,
            has_replayed_events = false
        },
        Replies};
reply(_Event, StateData) ->
    {next_state, complete_task, StateData}.

reply_and_keep_state(Event, StateData) ->
    Replies = [{reply, From, Event} || From <- StateData#state.executions_awaits],
    {keep_state,
        StateData#state{
            executions_awaits = [],
            has_upserted_events = false,
            has_replayed_events = false
        },
        Replies}.

is_deterministic(
    false, _CMod, {{marker, Type, _}, #{}}, {_, 'EVENT_TYPE_MARKER_RECORDED', _, _}, [
        {{{marker, Type, _}, #{}}, _} = IC | TIndexCommand
    ]
) when Type =:= "message"; Type =:= ~"message" ->
    {true, TIndexCommand, IC};
is_deterministic(false, _CMod, _, _Event, IndexCommand) ->
    {true, IndexCommand, []};
is_deterministic(true, _CMod, EventIdx, Event, []) ->
    {nondeterministic, #{
        actual_awaitable => EventIdx,
        actual_event => Event,
        expected_awaitable => [],
        expected_command => []
    }};
is_deterministic(true, CMod, EventIdx, Event, [{Idx, Cmd} = IC | TIndexCommand]) ->
    case temporal_sdk_api_workflow_check:is_deterministic(CMod, Idx, EventIdx, Cmd, Event) of
        true ->
            {true, TIndexCommand, IC};
        false ->
            {nondeterministic, #{
                actual_awaitable => EventIdx,
                actual_event => Event,
                expected_awaitable => Idx,
                expected_command => Cmd,
                deterministic_check_mod => CMod
            }}
    end.

handle_blocking_task(StateData) ->
    #state{
        api_ctx = ApiCtx,
        blocking_awaitable = BA,
        history_events = HE,
        index_table = ITable
    } = StateData,
    case temporal_sdk_api_awaitable:unblock_awaitable(BA, HE, ApiCtx, ITable) of
        ok ->
            reply(complete_await, StateData);
        noevent ->
            case StateData#state.grpc_req_ref of
                {get_history, _Ref} -> {keep_state, StateData};
                undefined -> {next_state, complete_task, StateData}
            end;
        Err ->
            {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end.

handle_mutation(
    true,
    {{{marker, _, _}, #{state := cmd}}, #{
        value_fun := VFn, opts := #{mutable := #{mutations_limit := Limit}}
    }} = IndexCommand,
    {{marker, _, _}, #{state := recorded, value := Value}} = EventIndex,
    HistoryTable
) when Limit > 0 ->
    try
        % TODO pass old value???
        % NewValue = VFn(Value),
        NewValue = VFn(),
        case NewValue =:= Value of
            true -> ignore;
            false -> do_mutation(NewValue, IndexCommand, EventIndex, HistoryTable)
        end
    catch
        Class:Reason:Stacktrace -> {mutation_catch, {Class, Reason, Stacktrace}}
    end;
handle_mutation(_IsReplaying, _IndexCommand, _EventIndex, _HistoryTable) ->
    ignore.

do_mutation(
    _NewValue,
    {{{marker, _Type, Name}, _IdxData}, #{opts := #{mutable := #{mutations_limit := Limit}}}},
    {{marker, _, _}, #{mutations_count := Count}},
    HistoryTable
) when Count < Limit ->
    REId = temporal_sdk_api_awaitable_history_table:reset_event_id(HistoryTable),
    {RRStr, _RRBin} = temporal_sdk_api_common:mutation_reset_reason(Name),
    {mutation_reset, REId, RRStr};
do_mutation(
    NewValue,
    {{{marker, Type, Name}, _IdxData}, #{
        opts := #{mutable := #{mutations_limit := Limit, fail_on_limit := true}}
    }},
    {{marker, _, _}, #{value := Value}},
    _HistoryTable
) ->
    FailureData = #{
        reason => "Marker mutations limit exceeded.",
        marker_name => Name,
        marker_type => Type,
        recorded_value => Value,
        current_value => NewValue,
        mutations_limit => Limit
    },
    {mutation_fail, FailureData};
do_mutation(
    NewValue,
    {{{marker, Type, Name}, _IdxData}, #{
        opts := #{mutable := #{mutations_limit := Limit, fail_on_limit := false}}
    }},
    {{marker, _, _}, #{value := Value}},
    _HistoryTable
) ->
    FailureData = #{
        marker_name => Name,
        marker_type => Type,
        recorded_value => Value,
        current_value => NewValue,
        mutations_limit => Limit
    },
    temporal_sdk_utils_logger:log_error(
        error, ?MODULE, ?FUNCTION_NAME, "Marker mutations limit exceeded.", FailureData
    ),
    ignore.

update_blocking_awaitable(
    'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED',
    {IK, #{event_id := EId}},
    {{IK, #{direct_result := true} = ID}, _Cmd},
    StateData
) ->
    StateData#state{blocking_awaitable = {IK, ID#{event_id => EId}}};
update_blocking_awaitable(_EventType, _EventIndex, _IndexCommand, StateData) ->
    StateData.

update_otp_msg_count(_IsReplaying, ignore_index, OtpMessagesCount) ->
    OtpMessagesCount;
update_otp_msg_count(false, _Event, OtpMessagesCount) ->
    OtpMessagesCount;
update_otp_msg_count(true, {{marker, Type, _}, #{state := recorded}}, OtpMessagesCount) when
    Type =:= "message"; Type =:= ~"message"
->
    #{recorded := {Current, Max}} = OtpMessagesCount,
    OtpMessagesCount#{recorded := {Current + 1, Max}};
update_otp_msg_count(true, _Event, OtpMessagesCount) ->
    OtpMessagesCount.

update_rcmds('EVENT_TYPE_ACTIVITY_TASK_SCHEDULED', [IK | TRCmds], [{{IK, _}, _} | _]) ->
    TRCmds;
update_rcmds('EVENT_TYPE_MARKER_RECORDED', [IK | TRCmds], [{{IK, _}, _} | _]) ->
    TRCmds;
update_rcmds(_EType, RCmds, _IndexCommand) ->
    RCmds.

handle_complete_task_enter(#state{grpc_req_ref = Ref} = StateData) when Ref =/= undefined ->
    gen_statem:cast(self(), fail_task),
    {keep_state, StateData#state{
        stop_reason = {error, "Invalid executor state: unexpected pending gRPC request.", ?EVST}
    }};
handle_complete_task_enter(
    #state{commands = [], pending_commands = [], history_events = HE} = StateData
) when HE =/= [] ->
    gen_statem:cast(self(), fail_task),
    {keep_state, StateData#state{
        stop_reason =
            {error,
                #{
                    reason =>
                        "Invalid executor state: expected empty wokflow history events list, got history events.",
                    unexpected_events => HE
                },
                ?EVST}
    }};
handle_complete_task_enter(#state{commands = [], pending_commands = PC} = StateData) when
    PC =/= []
->
    Fn = fun
        ({{IK, IV}, _Cmd}) ->
            #{awaitable => IK, approximate_data_size_bytes => byte_size(erlang:term_to_binary(IV))};
        (_) ->
            "invalid index_command"
    end,
    ErrA = lists:map(Fn, PC),
    gen_statem:cast(self(), fail_task),
    {keep_state, StateData#state{
        stop_reason =
            {error,
                #{
                    reason => "Workflow complete task size exceeds gRPC maximum_request_size.",
                    pending_awaitables => ErrA
                },
                ?EVST}
    }};
handle_complete_task_enter(#state{commands = [], caller_pid = CallerPid} = StateData) when
    is_pid(CallerPid)
->
    CallerPid ! {?TEMPORAL_SDK_REPLAY_TAG, StateData#state.execution_state},
    stop;
handle_complete_task_enter(#state{commands = C, caller_pid = CallerPid} = StateData) when
    is_pid(CallerPid)
->
    SR = {error, {nondeterministic, #{unexpected_command => hd(C)}}, ?EVST},
    CallerPid ! {?TEMPORAL_SDK_REPLAY_TAG, {error, SR}},
    {stop, normal, StateData#state{stop_reason = SR}};
handle_complete_task_enter(
    #state{api_ctx = #{task_opts := #{token := undefined}}, open_tasks_count = 0} = StateData
) ->
    Err = "Internal error: undefined task token while completing workflow task.",
    {stop, normal, StateData#state{stop_reason = {error, Err, ?EVST}}};
handle_complete_task_enter(#state{api_ctx = #{task_opts := #{token := undefined}}}) ->
    gen_statem:cast(self(), force_poll),
    keep_state_and_data;
handle_complete_task_enter(StateData) ->
    #state{
        api_ctx = ApiContext,
        open_tasks_count = OpenTasksCount,
        execution_state = ExecutionState,
        pending_commands = PendingCommands,
        queries = Queries,
        messages = Messages
    } = StateData,
    maybe
        {ok, Commands0} ?= update_event_id(StateData),
        {Commands, CommandsRest} = split_before_complete(Commands0, StateData),
        {_Awaitables, TemporalCommands} = lists:unzip(Commands),
        FN =
            (OpenTasksCount =:= 0 andalso ExecutionState =:= started) orelse PendingCommands =/= [],
        Req1 =
            case FN of
                true -> #{force_create_new_workflow_task => true};
                false -> #{}
            end,
        Req2 =
            case map_size(Queries) of
                0 -> Req1;
                _ -> Req1#{query_results => Queries}
            end,
        Req =
            case Messages of
                [] -> Req2;
                _ -> Req2#{messages => Messages}
            end,
        RefOrErr = temporal_sdk_api_workflow:respond_workflow_task_completed(
            ApiContext,
            TemporalCommands,
            Req
        ),
        case is_reference(RefOrErr) of
            true ->
                {keep_state,
                    StateData#state{
                        commands = Commands ++ CommandsRest,
                        grpc_req_ref = {complete_task, RefOrErr}
                    },
                    {{timeout, task_timeout}, cancel}};
            false ->
                gen_statem:cast(self(), fail_task),
                {keep_state, StateData#state{stop_reason = {error, RefOrErr, ?EVST}}}
        end
    else
        {update_event_id_error, MSD} ->
            gen_statem:cast(self(), fail_task),
            {keep_state, MSD};
        Err ->
            gen_statem:cast(self(), fail_task),
            {current_stacktrace, CS} = process_info(self(), current_stacktrace),
            {keep_state, StateData#state{stop_reason = {error, Err, CS}}}
    end.

split_before_complete(
    Commands, #state{execution_state = ES, await_open_before_close = true, open_tasks_count = OTC}
) when ES =/= started, OTC > 0 ->
    lists:split(length(Commands) - 1, Commands);
split_before_complete(Commands, _StateData) ->
    {Commands, []}.

handle_complete_task(
    {ok, _Response},
    #state{execution_state = ES, pending_commands = [], await_open_before_close = false} = StateData
) when ES =/= started ->
    {stop, normal, StateData};
handle_complete_task(
    {ok, _Response},
    #state{execution_state = ES, pending_commands = [], open_tasks_count = 0} = StateData
) when ES =/= started ->
    {stop, normal, StateData};
handle_complete_task({ok, #{reset_history_event_id := 0} = Response}, StateData) ->
    #state{
        task_workflow_execution = WorkflowExecution,
        task_timeout = TaskTimeout,
        commands = Commands,
        pending_commands = PendingCommands,
        completed_commands = CompletedCommands
    } = StateData,
    WorkflowTask = maps:get(workflow_task, Response, #{workflow_execution => WorkflowExecution}),
    ActivityTasks = maps:get(activity_tasks, Response, []),
    maybe
        {ok, HNE, HUE, SD1} ?= update_after_poll(sticky, WorkflowTask, StateData),
        {ok, SD2} ?= start_eager_activities(ActivityTasks, SD1),
        TTAction = {{timeout, task_timeout}, TaskTimeout, timeout},
        case PendingCommands of
            [] ->
                SD3 = SD2#state{
                    commands = CompletedCommands ++ Commands,
                    completed_commands = [],
                    queries = #{},
                    messages = []
                },
                case HNE orelse HUE of
                    false ->
                        {next_state, poll, SD3, TTAction};
                    true ->
                        {next_state, replay, SD3, [TTAction, {next_event, internal, handle_replay}]}
                end;
            _ ->
                {repeat_state,
                    SD2#state{
                        commands = PendingCommands,
                        pending_commands = [],
                        completed_commands = CompletedCommands ++ Commands,
                        queries = #{},
                        messages = []
                    },
                    TTAction}
        end
    else
        Err -> {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end;
handle_complete_task(
    {ok, #{reset_history_event_id := ResetEventId, workflow_task := Task}}, StateData
) when ResetEventId > 0 ->
    {stop, normal, restart_workflow(StateData, Task)};
handle_complete_task({ok, Response}, StateData) ->
    {stop, normal, StateData#state{
        stop_reason =
            {error,
                #{
                    reason => "Unhandled RespondWorkflowTaskCompletedResponse.",
                    invalid_response => Response
                },
                ?EVST}
    }};
handle_complete_task({error, #{reason := maximum_request_size_exceeded}}, StateData) ->
    #state{commands = Commands, pending_commands = PendingCommands} = StateData,
    SD = StateData#state{
        grpc_req_ref = undefined,
        commands = lists:droplast(Commands),
        pending_commands = [lists:last(Commands) | PendingCommands]
    },
    {repeat_state, SD};
handle_complete_task({error, #{grpc_response_headers := GH}} = Error, StateData) ->
    case proplists:get_value(~"grpc-message", GH, undefined) of
        ~"Workflow task not found." ->
            %% Ignore Temporal server PollWorkflowTaskQueueResponse race condition
            case StateData#state.open_tasks_count > 0 of
                true ->
                    {next_state, poll, StateData#state{grpc_req_ref = undefined}};
                false ->
                    {stop, normal, StateData#state{stop_reason = {error, Error, ?EVST}}}
            end;
        _ ->
            {stop, normal, StateData#state{stop_reason = {error, Error, ?EVST}}}
    end;
handle_complete_task(Error, StateData) ->
    {stop, normal, StateData#state{stop_reason = {error, Error, ?EVST}}}.

start_eager_activities([Task | TActivities], StateData) ->
    #{activity_type := #{name := ActivityType}, activity_id := ActivityId, task_token := Token} =
        Task,
    #state{
        api_ctx = #{limiter_counters := [_WorkflowLC, EagerLC, _DirectLC]},
        api_ctx_activity =
            #{cluster := Cluster, worker_opts := #{task_queue := TaskQueue} = WorkerOpts} =
                ApiCtxActivity,
        direct_execution_pids = DirectExecutionPids,
        linked_pids = LinkedPids
    } = StateData,

    ActivityIndexKey =
        temporal_sdk_api_awaitable_index:cast({activity, ActivityId}, ApiCtxActivity),
    case lists:keyfind(ActivityIndexKey, 1, DirectExecutionPids) of
        false ->
            maybe
                {ok, Mod} ?=
                    temporal_sdk_poller_adapter_utils:validate_temporal_task_name(
                        Cluster, WorkerOpts, ActivityType
                    ),
                AC = temporal_sdk_api_context:add_activity_opts(ApiCtxActivity, Task, Mod),
                {ok, _Pid} ?=
                    temporal_sdk_executor_activity:start(AC#{limiter_counters => [EagerLC]}, Task),
                start_eager_activities(TActivities, StateData)
            end;
        {ActivityIndexKey, Pid} ->
            gen_statem:cast(Pid, {?MSG_PRV, task_token, Token}),
            unlink(Pid),
            SD = StateData#state{
                direct_execution_pids = lists:keydelete(ActivityIndexKey, 1, DirectExecutionPids),
                linked_pids = lists:delete(Pid, LinkedPids)
            },
            start_eager_activities(TActivities, SD)
    end;
start_eager_activities([], #state{direct_execution_pids = []} = StateData) ->
    {ok, StateData};
start_eager_activities([], _StateData) ->
    {error,
        "Error when processing direct_execution activities. Is <system.enableActivityEagerExecution> enabled?"}.

handle_poll_enter(#state{grpc_req_ref = Ref} = StateData) when Ref =/= undefined ->
    gen_statem:cast(self(), fail_task),
    {keep_state, StateData#state{
        stop_reason = {error, "Invalid executor state: unexpected pending gRPC request.", ?EVST}
    }};
handle_poll_enter(StateData) ->
    case temporal_sdk_api_poll:poll_workflow_task_queue(StateData#state.api_ctx) of
        Ref when is_reference(Ref) ->
            {keep_state, StateData#state{grpc_req_ref = {poll, Ref}}, {
                {timeout, task_timeout}, cancel
            }};
        Err ->
            {stop, normal, StateData#state{
                stop_reason = {error, Err, ?EVST}, execution_state = error
            }}
    end.

handle_poll(
    info,
    {?TEMPORAL_SDK_GRPC_TAG, Ref,
        {ok, #{
            attempt := 0,
            previous_started_event_id := 0,
            started_event_id := 0,
            task_token := <<>>,
            queries := Q
        }}},
    #state{grpc_req_ref = {poll, Ref}} = StateData
) when map_size(Q) =:= 0 ->
    #state{api_ctx = ApiCtx} = StateData,
    case temporal_sdk_api_workflow:get_workflow_execution_history_reverse(ApiCtx, 1) of
        NRef when is_reference(NRef) ->
            {keep_state, StateData#state{grpc_req_ref = {get_history_reverse, NRef}}};
        Err ->
            {stop, normal, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end;
handle_poll(
    info,
    {?TEMPORAL_SDK_GRPC_TAG, Ref,
        {ok, #{history := #{events := [#{event_id := HistoryEventId} | _]}}}},
    #state{grpc_req_ref = {get_history_reverse, Ref}, event_id = EventId} = StateData
) when HistoryEventId =:= EventId; HistoryEventId =:= EventId + 1 ->
    {repeat_state, StateData#state{grpc_req_ref = undefined}};
handle_poll(
    info,
    {?TEMPORAL_SDK_GRPC_TAG, Ref, {ok, #{}}},
    #state{grpc_req_ref = {get_history_reverse, Ref}} = StateData
) ->
    {stop, normal, StateData#state{execution_state = stale}};
handle_poll(EventType, EventContent, StateData) ->
    handle_common(poll, EventType, EventContent, StateData).

handle_fail_task(#state{caller_pid = CallerPid} = StateData) when is_pid(CallerPid) ->
    CallerPid ! {?TEMPORAL_SDK_REPLAY_TAG, {error, StateData#state.stop_reason}},
    stop;
handle_fail_task(#state{api_ctx = #{task_opts := #{token := undefined}}} = StateData) ->
    {stop, normal, StateData#state{execution_state = error}};
handle_fail_task(#state{workflow_info = #{attempt := 1}} = StateData) ->
    #state{api_ctx = ApiCtx, stop_reason = StopReason} = StateData,
    AF = do_handle_fail_task(StateData),
    C = do_fail_cause(StateData),
    case temporal_sdk_api_workflow:respond_workflow_task_failed(ApiCtx, AF, C) of
        ok ->
            {stop, normal, StateData#state{execution_state = error}};
        Err ->
            SR = [{error, Err, ?EVST}, StopReason],
            {stop, normal, StateData#state{stop_reason = SR, execution_state = error}}
    end;
handle_fail_task(StateData) ->
    {stop, normal, StateData#state{execution_state = error}}.

% TODO: refactor blocking handle_failure/3 call to safe and async spawn handler
% including {{timeout, task_timeout}, cancel} action on enter
do_handle_fail_task(StateData) ->
    #state{stop_reason = {C, R, S}, execution_module = Mod} = StateData,
    case erlang:function_exported(Mod, handle_failure, 3) of
        true ->
            case Mod:handle_failure(C, R, S) of
                ignore -> #{source => C, message => R, stack_trace => S};
                F -> F
            end;
        false ->
            #{source => C, message => R, stack_trace => S}
    end.

do_fail_cause(#state{stop_reason = {error, {nondeterministic, _}, _}}) ->
    'WORKFLOW_TASK_FAILED_CAUSE_NON_DETERMINISTIC_ERROR';
do_fail_cause(_StateData) ->
    'WORKFLOW_TASK_FAILED_CAUSE_WORKFLOW_WORKER_UNHANDLED_FAILURE'.

handle_query_closed(
    #state{workflow_context = #{task := #{task_token := TT, query := Q}}} = StateData
) ->
    MsgName = 'temporal.api.workflowservice.v1.RespondQueryTaskCompletedRequest',
    #state{api_ctx = ApiContext, execution_module = Mod, history_events = HE} = StateData,
    {{query, QueryType}, QueryData} = temporal_sdk_api_awaitable_index:from_poll(Q, ApiContext),
    QD1 = maps:without([state], QueryData),
    QD = QD1#{query_type => QueryType},
    Response =
        case erlang:function_exported(Mod, handle_query, 2) of
            true -> Mod:handle_query(HE, QD);
            false -> #{error_message => "Undefined handle_query/2 callback."}
        end,
    DefaultResponse =
        [
            {answer, payloads, '$_optional', {MsgName, answer}},
            {error_message, unicode, '$_optional'},
            {failure, failure, '$_optional'}
        ],
    case temporal_sdk_utils_opts:build(DefaultResponse, Response, ApiContext) of
        {ok, R0} ->
            R = R0#{task_token => TT},
            % TODO: refactor blocking handle_query/2 call to safe & async spawn handler with timeout
            temporal_sdk_api_workflow:respond_query_task_completed(ApiContext, R),
            {stop, normal, StateData#state{execution_state = queried}};
        Err ->
            R = #{task_token => TT, error_message => "Invalid handle_query/2 callback return."},
            % TODO: refactor blocking handle_query/2 call to safe & async spawn handler with timeout
            temporal_sdk_api_workflow:respond_query_task_completed(ApiContext, R),
            {stop, normal, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end;
handle_query_closed(#state{workflow_context = #{task := T}} = StateData) ->
    Err = #{reason => "Polled unhandled workflow task.", workflow_task => T},
    {stop, normal, StateData#state{stop_reason = {error, Err, ?EVST}}}.

%% -------------------------------------------------------------------------------------------------
%% handle_common: gRPC PollWorkflowTaskQueueResponse
%%
%% Handle PollWorkflowTaskQueueResponse from regular or sticky task queue
handle_common(
    poll,
    info,
    {?TEMPORAL_SDK_GRPC_TAG, GRef, {ok, #{workflow_execution := WE} = Task}},
    #state{grpc_req_ref = {poll, _SRef}, task_workflow_execution = WE} = StateData
) ->
    AppendType =
        case GRef of
            regular_queue -> regular;
            _ -> sticky
        end,
    case update_after_poll(AppendType, Task, StateData) of
        {ok, _HNE, _HUE, SD} ->
            {next_state, replay, SD, [
                {{timeout, task_timeout}, StateData#state.task_timeout, timeout},
                {next_event, internal, handle_replay}
            ]};
        Err ->
            {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end;
%% Drop unsolicited PollWorkflowTaskQueueResponse racing with ongoing
%% GetWorkflowExecutionHistoryResponse or RespondWorkflowTaskCompletedResponse
%% and fetch external events like query, queries or updates
handle_common(
    _State,
    info,
    {?TEMPORAL_SDK_GRPC_TAG, _GRef, {ok, #{workflow_execution := WE} = Task}},
    #state{task_workflow_execution = WE} = StateData
) ->
    #state{api_ctx = ApiCtx, index_table = IT} = StateData,
    case temporal_sdk_api_awaitable_index_table:upsert_polled(IT, Task, ApiCtx) of
        {ok, _HUE} -> keep_state_and_data;
        Err -> {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end;
%% Handle PollWorkflowTaskQueueResponse after ResetWorkflowExecutionRequest
handle_common(
    _State,
    info,
    {?TEMPORAL_SDK_GRPC_TAG, _Ref, {ok, #{workflow_execution := WE1} = Task}},
    #state{task_workflow_execution = WE2} = StateData
) when WE1 =/= WE2 ->
    #{history := #{events := THistoryEvents}} = Task,
    case is_workflow_execution_reset(THistoryEvents) of
        true ->
            {stop, normal, restart_workflow(StateData, Task)};
        false ->
            {next_state, fail_task, StateData#state{
                stop_reason =
                    {error,
                        #{
                            reason => "Malformed workflow task polled from regular task queue.",
                            malformed_task => Task
                        },
                        ?EVST}
            }}
    end;
%% Handle empty PollWorkflowTaskQueueResponse
handle_common(
    State,
    info,
    {?TEMPORAL_SDK_GRPC_TAG, GRef,
        {ok, #{
            messages := [],
            previous_started_event_id := 0,
            started_event_id := 0,
            attempt := 0,
            task_token := <<>>,
            queries := #{},
            next_page_token := <<>>,
            backlog_count_hint := 0
        }}},
    #state{open_tasks_count = OTC} = StateData
) ->
    case is_reference(GRef) andalso State =:= poll andalso OTC =:= 0 of
        true ->
            %% empty task from sticky task queue and no open tasks
            {next_state, replay, StateData#state{grpc_req_ref = undefined}, [
                {{timeout, task_timeout}, StateData#state.task_timeout, timeout},
                {next_event, internal, handle_replay}
            ]};
        _ ->
            keep_state_and_data
    end;
%% -------------------------------------------------------------------------------------------------
%% handle_common: gRPC GetWorkflowExecutionHistoryResponse
handle_common(
    State,
    info,
    {?TEMPORAL_SDK_GRPC_TAG, _Ref,
        {ok, #{history := #{events := THE}, next_page_token := NPT, archived := _}}},
    StateData
) ->
    #state{history_events = HistoryEvents, event_id = EventId, history_table = HT} = StateData,
    maybe
        {ok, HE} ?=
            temporal_sdk_api_awaitable_history_table:append(get, EventId, HistoryEvents, THE, HT),
        {ok, SD} ?= maybe_get_workflow_execution_history(NPT, StateData#state{history_events = HE}),
        case State of
            replay -> handle_replay(SD);
            St when St =:= complete_task; St =:= poll -> {next_state, replay, SD};
            _ -> {keep_state, SD}
        end
    else
        Err -> {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end;
%% -------------------------------------------------------------------------------------------------
%% handle_common: handle message send by the temporal_sdk_poller_adapter_workflow_task_queue when
%% there are duplicate workflow executors running
handle_common(
    _State,
    info,
    {?TEMPORAL_SDK_GRPC_TAG, duplicate_workflow_execution},
    StateData
) ->
    {stop, normal, StateData#state{execution_state = duplicate}};
%% -------------------------------------------------------------------------------------------------
%% handle_common: ignore RespondWorkflowTaskCompletedResponse Temporal server double tap
%% (those duplicate responses carry corrupted event histories anyway)
handle_common(
    _State,
    info,
    {?TEMPORAL_SDK_GRPC_TAG, _Ref, {ok, #{reset_history_event_id := _}}},
    _StateData
) ->
    keep_state_and_data;
%% -------------------------------------------------------------------------------------------------
%% handle_common: marker
handle_common(replay, cast, {?MSG_PRV, marker, record, Pid, Value}, StateData) when is_pid(Pid) ->
    #state{api_ctx = ApiCtx, index_table = IT, commands = Commands, open_locals_count = OLC} =
        StateData,
    MsgName = 'temporal.api.command.v1.RecordMarkerCommandAttributes',
    maybe
        {Pid, {{{marker, Type, Name} = IdxKey, IdxVal}, #{opts := Opts}}} ?=
            lists:keyfind(Pid, 1, Commands),
        #{value_codec := ValueCodec} = Opts,
        Idx = {IdxKey, IdxVal#{value => Value}},
        ok ?= temporal_sdk_api_awaitable_index_table:upsert_index(IT, Idx),
        DetailsUsr = maps:get(details, Opts, #{}),
        {ok, EncValue, Decoder} ?= temporal_sdk_api_common:marker_encode_value(ValueCodec, Value),
        Details =
            temporal_sdk_api:map_to_mapstring_payloads(
                ApiCtx, MsgName, details, DetailsUsr#{"type" => [Type], "value" => EncValue}
            ),
        Attr1 = maps:merge(#{marker_name => Name, details => Details}, maps:with([header], Opts)),
        Attr = temporal_sdk_api_header:put_marker_sdk(Attr1, Opts, Type, Decoder, ApiCtx),
        Cmd = temporal_sdk_api_command:record_marker_command(Attr),
        UpdatedCommands = lists:keyreplace(Pid, 1, Commands, {Idx, Cmd}),
        SD = StateData#state{
            commands = UpdatedCommands, open_locals_count = OLC - 1, has_upserted_events = true
        },
        handle_replay(SD)
    else
        false ->
            {next_state, fail_task, StateData#state{
                stop_reason = {error, "Malformed workflow executor linked pids list.", ?EVST}
            }};
        {error, Reason} ->
            {next_state, fail_task, StateData#state{stop_reason = {error, Reason, ?EVST}}};
        Err ->
            {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end;
%% For message marker there is only command appended on record marker value event,
%% so we handle this in the execute state dedicated for the commands accumulation.
%% If record message marker value event is received during workflow execution replay it is postponed.
handle_common(
    execute,
    cast,
    {?MSG_PRV, marker, record, Name0, Value},
    #state{is_replaying = false} = StateData
) when not is_pid(Name0) ->
    #state{api_ctx = ApiCtx, commands = Commands} = StateData,
    MsgName = 'temporal.api.command.v1.RecordMarkerCommandAttributes',
    {marker, Type, Name} =
        IdxKey = temporal_sdk_api_awaitable_index:cast({marker, message, Name0}, ApiCtx),
    Details =
        temporal_sdk_api:map_to_mapstring_payloads(
            ApiCtx, MsgName, details, #{"type" => [Type], "value" => Value}
        ),
    Opts = #{mutable => false},
    Attr1 = #{marker_name => Name, details => Details},
    Attr = temporal_sdk_api_header:put_marker_sdk(Attr1, Opts, Type, none, ApiCtx),
    Cmd = temporal_sdk_api_command:record_marker_command(Attr),
    case next_event_id(StateData) of
        {ok, NEId} ->
            IdxCmd = {
                {IdxKey, #{
                    state => cmd,
                    execution_id => undefined,
                    details => Details,
                    value => Value,
                    event_id => NEId
                }},
                Cmd
            },
            SD = StateData#state{commands = Commands ++ [IdxCmd], has_upserted_events = true},
            {keep_state, SD};
        Err ->
            {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end;
handle_common(replay, cast, {?MSG_PRV, marker, record, Name, Value}, StateData) ->
    {next_state, fail_task, StateData#state{
        stop_reason =
            {error,
                #{
                    reason =>
                        "Invalid record marker return value type. Expected list of convertables.",
                    invalid_value => Value,
                    message_marker_name => Name
                },
                ?EVST}
    }};
handle_common(_State, cast, {?MSG_PRV, marker, record, _PidOrName, _Value}, _StateData) ->
    {keep_state_and_data, postpone};
handle_common(_State, cast, {?MSG_PRV, marker, ignore, _Name}, StateData) ->
    case check_message_limit(ignored, StateData) of
        {ok, SD} -> {keep_state, SD};
        Err -> {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end;
handle_common(
    State, cast, {?MSG_PRV, marker, fail_task, _Pid, {Message, Source, Stacktrace}}, StateData
) when State =:= execute; State =:= replay ->
    {next_state, fail_task, StateData#state{stop_reason = {Source, Message, Stacktrace}}};
handle_common(
    State, cast, {?MSG_PRV, marker, failed, _PidOrName, {Class, Reason, Stacktrace}}, StateData
) when State =:= execute; State =:= replay ->
    {next_state, fail_task, StateData#state{stop_reason = {Class, Reason, Stacktrace}}};
%% -------------------------------------------------------------------------------------------------
%% handle_common: OTP messages
handle_common(_State, info, {?TEMPORAL_SDK_OTP_TAG, Name, Value}, StateData) ->
    case check_message_limit(received, StateData) of
        {ok, SD} ->
            {keep_state, spawn_message_marker(Name, Value, SD)};
        {error, Reason} ->
            {next_state, fail_task, StateData#state{stop_reason = {error, Reason, ?EVST}}}
    end;
%% -------------------------------------------------------------------------------------------------
%% handle_common: direct execution result
handle_common(
    execute, cast, {?MSG_PRV, direct_execution, completed, _IndexKey, _Result}, _StateData
) ->
    {keep_state_and_data, postpone};
handle_common(
    State, cast, {?MSG_PRV, direct_execution, completed, IndexKey, Result}, StateData
) ->
    #state{index_table = IndexTable} = StateData,
    Index = {IndexKey, #{result => Result}},
    case temporal_sdk_api_awaitable_index_table:upsert_index(IndexTable, Index) of
        ok ->
            case State of
                replay -> handle_replay(StateData#state{has_upserted_events = true});
                _ -> {keep_state, StateData}
            end;
        {error, #{old_awaitable_data := #{state := S}}} when S =:= completed; S =:= canceled ->
            {keep_state, StateData};
        Err ->
            {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end;
handle_common(
    _State, cast, {?MSG_PRV, direct_execution, failed, IndexKey, StopReason}, StateData
) ->
    #state{index_table = IndexTable} = StateData,
    Index = {IndexKey, #{last_failure => StopReason}},
    case temporal_sdk_api_awaitable_index_table:upsert_index(IndexTable, Index) of
        ok -> keep_state_and_data;
        Err -> {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end;
%% -------------------------------------------------------------------------------------------------
%% handle_common: linked processes exits
handle_common(_State, info, {'EXIT', CP, timeout}, #state{caller_pid = CP} = _StateData) ->
    stop;
handle_common(_State, info, {'EXIT', Pid, normal}, StateData) ->
    #state{linked_pids = LinkedPids} = StateData,
    {keep_state, StateData#state{linked_pids = lists:delete(Pid, LinkedPids)}};
handle_common(_State, info, {'EXIT', _Pid, ?LINKED_PID_EXIT_REASON}, _StateData) ->
    keep_state_and_data;
handle_common(_State, info, {'EXIT', Pid, Reason}, StateData) ->
    {next_state, fail_task, StateData#state{
        stop_reason =
            {error, #{reason => "Linked process abnormal exit.", pid => Pid, exit_reason => Reason},
                ?EVST}
    }};
%% -------------------------------------------------------------------------------------------------
%% handle_common: force_poll cast
handle_common(complete_task, cast, force_poll, StateData) ->
    {next_state, poll, StateData};
%% -------------------------------------------------------------------------------------------------
%% handle_common: fail_task cast
handle_common(_State, cast, fail_task, StateData) ->
    {next_state, fail_task, StateData};
%% -------------------------------------------------------------------------------------------------
%% handle_common: timeout
handle_common(State, {timeout, Timeout}, timeout, StateData) ->
    #state{task_timeout = TT, run_timeout = RT} = StateData,
    Err = {Timeout, #{task_timeout_msec => TT, run_timeout_msec => RT, executor_state => State}},
    {next_state, fail_task, StateData#state{stop_reason = {error, Err, ?EVST}}};
%% -------------------------------------------------------------------------------------------------
%% handle_common: unhandled message
handle_common(State, EventType, EventContent, StateData) ->
    {stop, normal, StateData#state{
        stop_reason =
            {error,
                #{
                    reason => "Unhandled OTP event/message received by workflow executor process.",
                    executor_state => State,
                    event => EventType,
                    event_content => EventContent
                },
                ?EVST}
    }}.

is_workflow_execution_reset(HistoryEvents) ->
    case hd(lists:nthtail(length(HistoryEvents) - 3, HistoryEvents)) of
        #{
            attributes :=
                {workflow_task_failed_event_attributes, #{
                    cause := 'WORKFLOW_TASK_FAILED_CAUSE_RESET_WORKFLOW'
                }}
        } ->
            true;
        _ ->
            false
    end.

maybe_get_workflow_execution_history(_Token, #state{execution_state = ES} = StateData) when
    ES =/= started
->
    {ok, StateData#state{grpc_req_ref = undefined}};
maybe_get_workflow_execution_history(NPToken, StateData) when NPToken =:= <<>>; NPToken =:= "" ->
    {ok, StateData#state{grpc_req_ref = undefined}};
maybe_get_workflow_execution_history(NextPageToken, #state{api_ctx = ApiCtx} = StateData) ->
    case temporal_sdk_api_workflow:get_workflow_execution_history(ApiCtx, NextPageToken) of
        Ref when is_reference(Ref) -> {ok, StateData#state{grpc_req_ref = {get_history, Ref}}};
        Err -> Err
    end.

check_message_limit(Action, StateData) ->
    #state{otp_messages_count = OtpMessagesCount} = StateData,
    {OldCount, Max} = maps:get(Action, OtpMessagesCount),
    NewCount = OldCount + 1,
    case Max of
        infinity ->
            % eqwalizer:ignore
            {ok, StateData#state{otp_messages_count = OtpMessagesCount#{Action := {NewCount, Max}}}};
        _ ->
            case NewCount =< Max of
                true ->
                    {ok, StateData#state{
                        % eqwalizer:ignore
                        otp_messages_count = OtpMessagesCount#{Action := {NewCount, Max}}
                    }};
                false ->
                    {error, #{
                        reason => "OTP messages limit exceeded.",
                        Action => NewCount,
                        limit => Max
                    }}
            end
    end.

%% -------------------------------------------------------------------------------------------------
%% event_id helpers

next_event_id(#state{history_events = [], commands = [], event_id = EId}) ->
    {ok, EId + 1};
next_event_id(#state{commands = Cmds}) when Cmds =/= [] ->
    case lists:last(Cmds) of
        {{_IKey, #{event_id := EId}}, _Cmd} when is_integer(EId) ->
            {ok, EId + 1};
        {_Pid, {{_IKey, #{event_id := EId}}, _Cmd}} when is_integer(EId) ->
            {ok, EId + 1};
        Invalid ->
            {error, #{
                reason => "Expected awaitable with event_id key, received invalid.",
                invalid_awaitable => Invalid
            }}
    end;
next_event_id(#state{history_events = HE}) when HE =/= [] ->
    do_next_eid(HE, 1).

do_next_eid([{EId, T, _, _} | THE], _) when
    T =:= 'EVENT_TYPE_WORKFLOW_EXECUTION_STARTED';
    T =:= 'EVENT_TYPE_WORKFLOW_TASK_SCHEDULED';
    T =:= 'EVENT_TYPE_WORKFLOW_TASK_STARTED';
    T =:= 'EVENT_TYPE_WORKFLOW_TASK_COMPLETED';
    T =:= 'EVENT_TYPE_WORKFLOW_TASK_TIMED_OUT';
    T =:= 'EVENT_TYPE_WORKFLOW_TASK_FAILED'
->
    do_next_eid(THE, EId + 1);
do_next_eid([{EId, _, _, _} | _THE], _) ->
    {ok, EId};
do_next_eid([], EId) ->
    {ok, EId + 1}.

update_event_id(true, EventId, [{{_IK, #{event_id := EId}}, _C} | _] = Cmds, StateData) when
    EId < EventId
->
    do_upeid(Cmds, EventId - 1, StateData, []);
update_event_id(_IsCommanded, _EventId, Cmds, _StateData) ->
    {ok, Cmds}.

update_event_id(#state{commands = []}) ->
    {ok, []};
update_event_id(#state{
    event_id = EId, commands = [{{_IK, #{event_id := EIdC}}, _} | _] = Cmds, history_events = HE
}) when EIdC >= EId + length(HE) + 1 ->
    {ok, Cmds};
update_event_id(StateData) ->
    #state{event_id = EId, commands = Cmds, history_events = HE} = StateData,
    do_upeid(Cmds, EId + length(HE), StateData, []).

do_upeid(
    [
        {{{activity, _}, #{state := cmd, cancel_requested := true}}, #{
            command_type := 'COMMAND_TYPE_REQUEST_CANCEL_ACTIVITY_TASK'
        }} = IC
        | TCmds
    ],
    EId,
    SD,
    NC
) ->
    case temporal_sdk_api_awaitable_index_table:update_cancelation(SD#state.index_table, IC, EId) of
        {ok, NIC} -> do_upeid(TCmds, EId + 1, SD, [NIC | NC]);
        Err -> {update_event_id_error, SD#state{stop_reason = {error, Err, ?EVST}}}
    end;
do_upeid([{{_IK, #{event_id := _}}, Cmd} = IC | TCmds], EId, SD, NC) ->
    case upsert_index(IC, EId + 1, SD) of
        {ok, NI} -> do_upeid(TCmds, EId + 1, SD, [{NI, Cmd} | NC]);
        {error, SD1} -> {update_event_id_error, SD1}
    end;
do_upeid([], _EId, _SD, NC) ->
    {ok, lists:reverse(NC)}.

%% -------------------------------------------------------------------------------------------------
%% commands helpers

%% do_cmds: info
do_cmds([{{{info, _InfoId}, _InfoValue} = I, sdk_command} | CT], started, SD, FC, EId) ->
    case temporal_sdk_api_awaitable_index_table:upsert_index(SD#state.index_table, I) of
        ok -> do_cmds(CT, started, SD, FC, EId);
        Err -> {error, SD#state{stop_reason = {error, Err, ?EVST}}}
    end;
%% do_cmds: execution
do_cmds(
    [{{{execution, ExeId}, #{state := cmd, mfa := {M, F, A}}} = I, sdk_command} | CT],
    started,
    SD,
    FC,
    EId
) ->
    maybe
        ok ?= temporal_sdk_api_awaitable_index_table:upsert_index(SD#state.index_table, I),
        {ok, SD1} ?= spawn_execution(M, F, A, ExeId, SD),
        do_cmds(CT, started, SD1, FC, EId)
    else
        Err -> {error, SD#state{stop_reason = {error, Err, ?EVST}}}
    end;
do_cmds([{{{execution, _ExeId}, #{}} = I, sdk_command} | CT], started, SD, FC, EId) ->
    case temporal_sdk_api_awaitable_index_table:upsert_index(SD#state.index_table, I) of
        ok -> do_cmds(CT, started, SD, FC, EId);
        Err -> {error, SD#state{stop_reason = {error, Err, ?EVST}}}
    end;
%% do_cmds: workflow closing commands
do_cmds([{{{complete_workflow_execution}, #{result := R}}, C} = IC], started, SD, FC, EId) ->
    case upsert_index(IC, EId, SD) of
        {ok, NI} ->
            do_cmds(
                [], completed, SD#state{execution_state = {completed, R}}, [{NI, C} | FC], EId + 1
            );
        Err ->
            Err
    end;
do_cmds([{{{cancel_workflow_execution}, #{details := D}}, C} = IC], started, SD, FC, EId) ->
    case upsert_index(IC, EId, SD) of
        {ok, NI} ->
            do_cmds(
                [], canceled, SD#state{execution_state = {canceled, D}}, [{NI, C} | FC], EId + 1
            );
        Err ->
            Err
    end;
do_cmds([{{{fail_workflow_execution}, #{failure := F}}, C} = IC], started, SD, FC, EId) ->
    case upsert_index(IC, EId, SD) of
        {ok, NI} ->
            do_cmds(
                [], failed, SD#state{execution_state = {failed, F}}, [{NI, C} | FC], EId + 1
            );
        Err ->
            Err
    end;
do_cmds([{{{continue_as_new_workflow}, #{} = IV}, C} = IC], started, SD, FC, EId) ->
    case upsert_index(IC, EId, SD) of
        {ok, NI} ->
            St = {continued_as_new, maps:with([task_queue, workflow_type], IV)},
            do_cmds([], continued_as_new, SD#state{execution_state = St}, [{NI, C} | FC], EId + 1);
        Err ->
            Err
    end;
do_cmds([{{{IK}, #{}}, _C} | TCmds], started, SD, _FC, _EId) when
    IK =:= complete_workflow_execution;
    IK =:= cancel_workflow_execution;
    IK =:= fail_workflow_execution;
    IK =:= continue_as_new_workflow
->
    {error, SD#state{
        stop_reason =
            {error,
                #{
                    reason => "Further commands after workflow closing command are not allowed.",
                    violating_commands => TCmds,
                    closing_command => IK
                },
                ?EVST}
    }};
%% do_cmds: running marker
do_cmds([{Pid, {{{marker, _, _}, #{state := cmd}}, C} = IC} | CT], started, SD, FC, EId) ->
    case upsert_index(IC, EId, SD) of
        {ok, NI} -> do_cmds(CT, started, SD, [{Pid, {NI, C}} | FC], EId + 1);
        Err -> Err
    end;
%% do_cmds: cancelations
do_cmds(
    [{{{activity, _} = IK, #{cancel_requested := true} = IV}, sdk_command} | CT],
    started,
    SD,
    FC,
    EId
) ->
    case temporal_sdk_api_awaitable_index_table:upsert_cancelation(SD#state.index_table, IK) of
        {ok, SEId, IVal} ->
            SD1 = cancel_request_direct_execution({IK, IVal}, SD),
            NI = {IK, IV#{event_id => EId, state => cmd}},
            C = temporal_sdk_api_command:request_cancel_activity_task_command(#{
                scheduled_event_id => SEId
            }),
            do_cmds(CT, started, SD1, [{NI, C} | FC], EId + 1);
        {error, Reason} ->
            {error, SD#state{stop_reason = {error, Reason, ?EVST}}}
    end;
do_cmds(
    [{{{timer, _} = IK, #{cancel_requested := true} = IV}, sdk_command} | CT],
    started,
    SD,
    FC,
    EId
) ->
    case temporal_sdk_api_awaitable_index_table:upsert_cancelation(SD#state.index_table, IK) of
        {ok, _SEId, _IVal} ->
            NI = {IK, IV#{event_id => EId, state => cmd}},
            C = temporal_sdk_api_command:cancel_timer_command(IK),
            %% 'COMMAND_TYPE_CANCEL_TIMER' is a deadlocking Temporal command
            #state{open_tasks_count = OTC} = SD,
            do_cmds(CT, started, SD#state{open_tasks_count = OTC - 1}, [{NI, C} | FC], EId + 1);
        {error, Reason} ->
            {error, SD#state{stop_reason = {error, Reason, ?EVST}}}
    end;
%% do_cmds: query
do_cmds([{{{query, QT} = IK, IV}, sdk_command} | CT], started, SD, FC, EId) ->
    #state{api_ctx = ApiCtx, index_table = IT, queries = Queries} = SD,
    case temporal_sdk_api_awaitable_index_table:fetch(IT, IK) of
        #{state := requested, history := H} = Qs when is_list(H) ->
            QsLi = [maps:without([history], Qs) | H],
            case do_respond_queries(QsLi, IK, IV, ApiCtx, IT, [], #{}) of
                {ok, NewQs} ->
                    do_cmds(CT, started, SD#state{queries = maps:merge(Queries, NewQs)}, FC, EId);
                Err ->
                    {error, SD#state{stop_reason = {error, Err, ?EVST}}}
            end;
        #{state := requested} = Q ->
            case do_respond_queries([Q], IK, IV, ApiCtx, IT, [], #{}) of
                {ok, NewQs} ->
                    do_cmds(CT, started, SD#state{queries = maps:merge(Queries, NewQs)}, FC, EId);
                Err ->
                    {error, SD#state{stop_reason = {error, Err, ?EVST}}}
            end;
        #{state := responded} ->
            {error, SD#state{
                stop_reason =
                    {error, #{reason => "Duplicate query response.", query_type => QT}, ?EVST}
            }};
        Invalid ->
            {error, SD#state{
                stop_reason =
                    {error,
                        #{
                            reason => "Expected query awaitable got unhandled awaitable.",
                            invalid_awaitable => Invalid
                        },
                        ?EVST}
            }}
    end;
%% do_cmds: remaining SDK commands
do_cmds([{I, sdk_command} | CT], started, SD, FC, EId) ->
    case temporal_sdk_api_awaitable_index_table:upsert_index(SD#state.index_table, I) of
        ok -> do_cmds(CT, started, SD, FC, EId);
        Err -> {error, SD#state{stop_reason = {error, Err, ?EVST}}}
    end;
%% do_cmds: remaining Temporal commands
do_cmds([{_I, C} = IC | CT], started, SD, FC, EId) ->
    case upsert_index(IC, EId, SD) of
        {ok, NI} ->
            #state{open_tasks_count = OTC} = SD,
            NOTC = OTC + temporal_sdk_api_command:awaitable_command_count(IC),
            do_cmds(CT, started, SD#state{open_tasks_count = NOTC}, [{NI, C} | FC], EId + 1);
        Err ->
            Err
    end;
%% do_cmds: maybe add complete_workflow_execution command
do_cmds([], started, #state{open_executions_count = 0} = SD, FC, EId) ->
    #state{api_ctx = ApiCtx, workflow_result = Result} = SD,
    IdxKey = {complete_workflow_execution},
    IdxValue = #{state => cmd, execution_id => undefined, result => Result},
    Cmd = temporal_sdk_api_command:complete_workflow_execution_command(ApiCtx, Result),
    case upsert_index({{IdxKey, IdxValue}, Cmd}, EId, SD) of
        {ok, NI} ->
            {ok, SD#state{execution_state = {completed, Result}}, lists:reverse([{NI, Cmd} | FC])};
        Err ->
            {error, SD#state{stop_reason = {error, Err, ?EVST}}}
    end;
%% do_cmds: finalize
do_cmds([], _EState, SD, FC, _EId) ->
    {ok, SD, lists:reverse(FC)};
do_cmds(C, ClosedState, SD, _FC, _EId) ->
    {error, SD#state{
        stop_reason =
            {error,
                #{
                    reason => "Further commands after workflow closing command are not allowed.",
                    closed_workflow_state => ClosedState,
                    violating_commands => C
                },
                ?EVST}
    }}.

do_respond_queries(
    [#{state := requested, '_sdk_data' := {token, TT}} = QVal | TQueries],
    Query,
    {IdxVal, Response} = IVal,
    ApiContext,
    IndexTable,
    HistoryAcc,
    QueriesAcc
) ->
    temporal_sdk_api_workflow:respond_query_task_completed(ApiContext, Response#{task_token => TT}),
    Q1 = maps:without(['_sdk_data'], QVal),
    Q2 = maps:merge(Q1, IdxVal),
    NewHAcc = [Q2#{state := responded} | HistoryAcc],
    do_respond_queries(TQueries, Query, IVal, ApiContext, IndexTable, NewHAcc, QueriesAcc);
do_respond_queries(
    [#{state := requested, '_sdk_data' := {id, Id}} = QVal | TQueries],
    Query,
    {IdxVal, Response} = IVal,
    ApiContext,
    IndexTable,
    HistoryAcc,
    QueriesAcc
) ->
    Q1 = maps:without(['_sdk_data'], QVal),
    Q2 = maps:merge(Q1, IdxVal),
    NewHAcc = [Q2#{state := responded} | HistoryAcc],
    R =
        case Response of
            #{answer := _} -> Response#{result_type => 'QUERY_RESULT_TYPE_ANSWERED'};
            #{} -> Response#{result_type => 'QUERY_RESULT_TYPE_FAILED'}
        end,
    NewQAcc = QueriesAcc#{Id => R},
    do_respond_queries(TQueries, Query, IVal, ApiContext, IndexTable, NewHAcc, NewQAcc);
do_respond_queries(
    [#{state := responded} = QVal | TQueries],
    Query,
    IVal,
    ApiContext,
    IndexTable,
    HistoryAcc,
    QueriesAcc
) ->
    NewHAcc = [QVal | HistoryAcc],
    do_respond_queries(TQueries, Query, IVal, ApiContext, IndexTable, NewHAcc, QueriesAcc);
do_respond_queries(
    [],
    Query,
    _IVal,
    _ApiContext,
    IndexTable,
    HistoryAcc,
    QueriesAcc
) ->
    Idx =
        case lists:reverse(HistoryAcc) of
            [IVal] -> {Query, IVal};
            [IVal | HIVal] when is_map(IVal) -> {Query, IVal#{history => HIVal}}
        end,
    case temporal_sdk_api_awaitable_index_table:upsert_index(IndexTable, Idx) of
        ok -> {ok, QueriesAcc};
        Err -> Err
    end.

upsert_index({{IdxKey, IdxVal}, _Cmd}, EventId, StateData) ->
    #state{index_table = IndexTable} = StateData,
    Idx = {IdxKey, IdxVal#{event_id => EventId}},
    case temporal_sdk_api_awaitable_index_table:upsert_index(IndexTable, Idx) of
        ok -> {ok, Idx};
        Err -> {error, StateData#state{stop_reason = {error, Err, ?EVST}}}
    end.

cancel_request_direct_execution({IndexKey, #{direct_execution := true}}, StateData) ->
    #state{direct_execution_pids = DirectExecutionPids, linked_pids = LinkedPids} = StateData,
    case lists:keyfind(IndexKey, 1, StateData#state.direct_execution_pids) of
        false ->
            StateData;
        {IndexKey, Pid} ->
            gen_statem:cast(Pid, {?MSG_PRV, direct_cancel_request}),
            unlink(Pid),
            StateData#state{
                direct_execution_pids = lists:keydelete(IndexKey, 1, DirectExecutionPids),
                linked_pids = lists:delete(Pid, LinkedPids)
            }
    end;
cancel_request_direct_execution(_Index, StateData) ->
    StateData.

do_rcmds(
    [{{{activity, _}, #{state := cmd, direct_execution := true}}, _} = IdxCmd | CT], TC, SD
) ->
    case spawn_activity(IdxCmd, SD) of
        {ok, _Pid, SD1} -> do_rcmds(CT, [IdxCmd | TC], SD1);
        Err -> Err
    end;
do_rcmds([{{{marker, _, _}, #{state := cmd}}, _} = IdxCmd | CT], TC, SD) ->
    {Pid, SD1} = spawn_marker(IdxCmd, SD),
    do_rcmds(CT, [{Pid, IdxCmd} | TC], SD1);
do_rcmds([IdxCmd | CT], TC, SD) ->
    do_rcmds(CT, [IdxCmd | TC], SD);
do_rcmds([], TC, SD) ->
    {ok, lists:reverse(TC), SD}.

%% -------------------------------------------------------------------------------------------------
%% spawn helpers

spawn_main_execution(StateData) ->
    #state{
        api_ctx = #{worker_opts := #{task_settings := #{execution_id := ExecutionId}}},
        execution_module = ExecutionModule,
        task_input = TaskInput,
        index_table = IndexTable
    } = StateData,
    IndexKey = {execution, ExecutionId},
    IndexValue = #{state => cmd, mfa => {ExecutionModule, execute, TaskInput}},
    case temporal_sdk_api_awaitable_index_table:upsert_index(IndexTable, {IndexKey, IndexValue}) of
        ok -> spawn_execution(ExecutionModule, execute, TaskInput, ExecutionId, StateData);
        Err -> Err
    end.

spawn_execution(Module, Function, Args, ExecutionId, StateData) ->
    #state{
        api_ctx = ApiCtx,
        api_ctx_activity = ApiCtxActivity,
        workflow_context = WorkflowContext,
        open_executions_count = OpenExecutionsCount,
        total_executions_count = TotalExecutionsCount,
        linked_pids = LinkedPids,
        otel_ctx = OtelCtx,
        history_table = HistoryTable,
        index_table = IndexTable,
        proc_label = ProcLabel,
        is_replaying = IsReplaying
    } = StateData,
    ExecutorPid = self(),
    Ctx = WorkflowContext#{execution_id := ExecutionId, is_replaying := IsReplaying},
    EvMetadata = maps:without([scheduled_time, started_time], StateData#state.ev_metadata),
    ExecutionIdx = TotalExecutionsCount + 1,
    SD_EV = StateData#state{ev_metadata = EvMetadata#{execution_id => ExecutionId}},
    ExecutionProcLabel = temporal_sdk_utils_path:string_path([ProcLabel, execution, ExecutionId]),
    T = ?EV(SD_EV, [execution, start]),

    IndexKey = {execution, ExecutionId},
    Index = {IndexKey, #{state => started}},
    % eqwalizer:ignore
    case temporal_sdk_api_awaitable_index_table:upsert_index(IndexTable, Index) of
        ok ->
            SpawnPid = spawn_opt(
                fun() ->
                    proc_lib:set_label(ExecutionProcLabel),
                    temporal_sdk_executor:set_executor_dict(
                        ExecutorPid,
                        ExecutionId,
                        ExecutionIdx,
                        ApiCtx,
                        ApiCtxActivity,
                        OtelCtx,
                        HistoryTable,
                        IndexTable
                    ),
                    otel_ctx:attach(OtelCtx),
                    % TODO start new otel span
                    try
                        Result = Module:Function(Ctx, Args),
                        ?EV(SD_EV, [execution, stop], T),
                        IdxCmd =
                            {
                                {{execution, ExecutionId}, #{state => completed, result => Result}},
                                sdk_command
                            },
                        Cmds = temporal_sdk_executor:get_commands() ++ [IdxCmd],
                        gen_statem:cast(
                            ExecutorPid, {?MSG_PRV, {execution, completed, ExecutionIdx, Cmds}}
                        )
                    catch
                        Class:Reason:Stacktrace ->
                            ?EV(SD_EV, [execution, exception], T, {Class, Reason, Stacktrace}),
                            gen_statem:cast(
                                ExecutorPid,
                                {?MSG_PRV,
                                    {execution, failed, ExecutionId, {Class, Reason, Stacktrace}}}
                            ),
                            erlang:raise(Class, Reason, Stacktrace)
                    end
                end,
                [link, {min_heap_size, 5_000}]
            ),
            Pid =
                case SpawnPid of
                    {P, _MonitorRef} -> P;
                    P -> P
                end,
            {ok, StateData#state{
                open_executions_count = OpenExecutionsCount + 1,
                total_executions_count = TotalExecutionsCount + 1,
                linked_pids = [Pid | LinkedPids]
            }};
        Err ->
            Err
    end.

spawn_local([], _ExecutionIdx, StateData) ->
    {ok, StateData};
spawn_local(NewCommands, ExecutionIdx, StateData) ->
    #state{is_replaying = IsR, executions_commands = EC} = StateData,
    case do_sloc(IsR, NewCommands, StateData, [], []) of
        {ok, SD, Cmds, RCmds} ->
            {ok, SD#state{executions_commands = [{ExecutionIdx, Cmds, RCmds} | EC]}};
        Err ->
            Err
    end.

%% CT  - Commands Tail
%% TC  - TemporalCommands
%% RC  - ReplayedCommands
do_sloc(
    true,
    [{{{activity, _} = IK, #{state := cmd, direct_execution := true}}, _} = C | CT],
    SD,
    TC,
    RC
) ->
    do_sloc(true, CT, SD, [C | TC], [IK | RC]);
do_sloc(
    false,
    [{{{activity, _}, #{state := cmd, direct_execution := true}}, _} = C | CT],
    SD,
    TC,
    RC
) ->
    case spawn_activity(C, SD) of
        {ok, _Pid, SD1} -> do_sloc(false, CT, SD1, [C | TC], RC);
        Err -> {error, Err, SD}
    end;
do_sloc(true, [{{{marker, _, _} = IK, #{state := cmd}}, _} = C | CT], SD, TC, RC) ->
    do_sloc(true, CT, SD, [C | TC], [IK | RC]);
do_sloc(false, [{{{marker, _, _}, #{state := cmd}}, _} = C | CT], SD, TC, RC) ->
    {Pid, SD1} = spawn_marker(C, SD),
    do_sloc(false, CT, SD1, [{Pid, C} | TC], RC);
do_sloc(IsReplaying, [C | CT], SD, TC, RC) ->
    do_sloc(IsReplaying, CT, SD, [C | TC], RC);
do_sloc(_IsReplaying, [], SD, TC, RC) ->
    {ok, SD, TC, RC}.

spawn_activity({{{activity, _} = IK, #{activity_type := AType}}, _} = IdxCmd, SD) ->
    #state{
        api_ctx = #{limiter_counters := [_WorkflowLC, _EagerLC, DirectLC]} = ApiCtx,
        api_ctx_activity = #{cluster := Cluster, worker_opts := WOpts} = ApiCtxActivity,
        linked_pids = LP,
        direct_execution_pids = DEP
    } = SD,
    maybe
        {ok, Mod} ?=
            temporal_sdk_poller_adapter_utils:validate_temporal_task_name(Cluster, WOpts, AType),
        SynTask = temporal_sdk_api_command:schedule_activity_task_command_to_task(IdxCmd, ApiCtx),
        AC = temporal_sdk_api_context:add_activity_opts(ApiCtxActivity, SynTask, IK, Mod),
        {ok, Pid} ?=
            temporal_sdk_executor_activity:start_link(AC#{limiter_counters => [DirectLC]}, SynTask),
        {ok, Pid, SD#state{
            linked_pids = [Pid | LP],
            direct_execution_pids = [{IK, Pid} | DEP]
        }}
    end.

spawn_marker({{{marker, _, _}, #{}}, #{value_fun := MarkerValueFun}}, StateData) ->
    #state{linked_pids = LP, open_locals_count = OLC} = StateData,
    ExecutorPid = self(),
    Pid = spawn_link(
        fun() ->
            try
                Result =
                    case MarkerValueFun of
                        FnV when is_function(MarkerValueFun, 0) -> FnV();
                        {M, F} when is_atom(M), is_atom(F) -> M:F();
                        {M, F, A} when is_atom(M), is_atom(F) -> apply(M, F, A)
                    end,
                gen_statem:cast(ExecutorPid, {?MSG_PRV, marker, record, self(), Result})
            catch
                Class:Reason:StackT ->
                    gen_statem:cast(
                        ExecutorPid, {?MSG_PRV, marker, failed, self(), {Class, Reason, StackT}}
                    )
            end
        end
    ),
    {Pid, StateData#state{linked_pids = [Pid | LP], open_locals_count = OLC + 1}}.

spawn_message_marker(Name, Value, StateData) ->
    #state{linked_pids = LP, execution_module = ExecutionModule} = StateData,
    ExecutorPid = self(),
    Pid = spawn_link(
        fun() ->
            try
                case ExecutionModule:handle_message(Name, Value) of
                    {record, V} ->
                        gen_statem:cast(ExecutorPid, {?MSG_PRV, marker, record, Name, V});
                    {fail, {_, _, _} = R} ->
                        gen_statem:cast(ExecutorPid, {?MSG_PRV, marker, fail_task, Name, R});
                    ignore ->
                        gen_statem:cast(ExecutorPid, {?MSG_PRV, marker, ignore, Name})
                end
            catch
                Class:Reason:StackT ->
                    gen_statem:cast(
                        ExecutorPid,
                        {?MSG_PRV, marker, failed, self(), {Class, Reason, StackT}}
                    )
            end
        end
    ),
    StateData#state{linked_pids = [Pid | LP]}.

%% -------------------------------------------------------------------------------------------------
%% executor helpers

-spec update_after_poll(
    AppendType :: sticky | regular,
    Task :: temporal_sdk_workflow:task(),
    StateData :: state()
) ->
    {ok, HasNewEvents :: boolean(), HasUpsertedEvents :: boolean(), UpdatedStateData :: state()}
    | {malformed_workflow_events_history, #{
        expected_event_id := pos_integer(), received_event_id := pos_integer()
    }}
    | {error, Reason :: term()}.
update_after_poll(
    AppendType,
    #{workflow_execution := WE, next_page_token := NPT, history := #{events := THE}} = Task,
    #state{task_workflow_execution = WE} = StateData
) ->
    #state{
        api_ctx = ApiCtx,
        history_events = HistoryEvents,
        event_id = EventId,
        index_table = IndexTable,
        has_upserted_events = HasUpsertedEvents,
        history_table = HT
    } = StateData,
    maybe
        {ok, HUE} ?= temporal_sdk_api_awaitable_index_table:upsert_polled(IndexTable, Task, ApiCtx),
        {ok, NewHE} ?=
            temporal_sdk_api_awaitable_history_table:append(
                AppendType, EventId, HistoryEvents, THE, HT
            ),
        {ok, SD1} ?= maybe_get_workflow_execution_history(NPT, StateData),
        SD2 =
            case Task of
                #{scheduled_time := _, started_time := _} ->
                    SD1#state{api_ctx = temporal_sdk_api_context:update(ApiCtx, Task)};
                #{} ->
                    SD1#state{
                        api_ctx = temporal_sdk_api_context:update(ApiCtx, #{task_token => undefined})
                    }
            end,
        SD = SD2#state{has_upserted_events = HasUpsertedEvents orelse HUE},
        case NewHE =:= HistoryEvents of
            true -> {ok, false, HUE, SD};
            false -> {ok, true, HUE, SD#state{history_events = NewHE}}
        end
    else
        Err -> Err
    end;
update_after_poll(
    AppendType,
    #{workflow_execution := WE, next_page_token := _} = Task,
    #state{task_workflow_execution = WE} = StateData
) ->
    update_after_poll(AppendType, Task#{history => #{events => []}}, StateData);
update_after_poll(
    AppendType,
    #{workflow_execution := WE, history := #{events := _}} = Task,
    #state{task_workflow_execution = WE} = StateData
) ->
    update_after_poll(AppendType, Task#{next_page_token => <<>>}, StateData);
update_after_poll(
    AppendType,
    #{workflow_execution := WE} = Task,
    #state{task_workflow_execution = WE} = StateData
) ->
    update_after_poll(
        AppendType, Task#{history => #{events => []}, next_page_token => <<>>}, StateData
    );
update_after_poll(_AppendType, #{workflow_execution := WE1}, #state{task_workflow_execution = WE2}) ->
    {error, #{
        reason => "Polled workflow task with mismatched workflow execution.",
        received_workflow_execution => WE1,
        expected_workflow_execution => WE2
    }}.

fetch_run_timeout(#{task_settings := #{run_timeout_ratio := Ratio}}, Task) ->
    case temporal_sdk_api_workflow_task:workflow_run_timeout_msec(Task) of
        T when is_integer(T), T > 0 -> round(T * Ratio);
        _ -> infinity
    end.

fetch_task_timeout(#{task_settings := #{task_timeout_ratio := Ratio}}, Task) ->
    case temporal_sdk_api_workflow_task:workflow_task_timeout_msec(Task) of
        T when is_integer(T), T > 0 -> round(T * Ratio);
        _ -> infinity
    end.

get_workflow_info(#state{workflow_info = WI} = StateData) ->
    WI#{
        event_id => StateData#state.event_id - 1,
        is_replaying => StateData#state.is_replaying,
        attempt => StateData#state.task_attempt,
        open_executions_count => StateData#state.open_executions_count,
        total_executions_count => StateData#state.total_executions_count,
        open_tasks_count => StateData#state.open_tasks_count,
        otp_messages_count => maps:map(
            fun(_Key, {Current, _Max}) -> Current end, StateData#state.otp_messages_count
        )
    }.

restart_workflow(StateData, Task) ->
    #state{api_ctx = ApiCtx} = StateData,
    SD = cleanup(StateData),
    AC = temporal_sdk_api_context:restart_workflow_task_opts(ApiCtx, Task),
    temporal_sdk_executor_workflow:start(AC, Task, undefined),
    SD.

start_ets(Int, StateData) ->
    {HistoryTableName, IndexTableName} =
        temporal_sdk_scope:build_ets_ids(StateData#state.api_ctx, Int),
    case {ets:whereis(HistoryTableName), ets:whereis(IndexTableName)} of
        {undefined, undefined} ->
            HistoryTable = ets:new(HistoryTableName, [ordered_set, {read_concurrency, true}]),
            IndexTable = ets:new(IndexTableName, [set, {read_concurrency, true}]),
            WorkflowContext = StateData#state.workflow_context,
            {ok, StateData#state{
                history_table = HistoryTable,
                index_table = IndexTable,
                workflow_context = WorkflowContext#{
                    history_table := HistoryTable, index_table := IndexTable
                }
            }};
        _ ->
            duplicate_ets_table
    end.

stop_ets(#state{history_table = undefined, index_table = undefined} = StateData) ->
    StateData;
stop_ets(#state{history_table = HistoryTable, index_table = IndexTable} = StateData) ->
    ets:delete(HistoryTable),
    ets:delete(IndexTable),
    StateData#state{history_table = undefined, index_table = undefined}.

kill_pids(StateData) ->
    #state{linked_pids = LinkedPids, direct_execution_pids = DirectExecutionPids} = StateData,
    {_IdxKey, DEP} = lists:unzip(DirectExecutionPids),
    lists:foreach(
        fun(Pid) when is_pid(Pid) ->
            unlink(Pid),
            gen_statem:cast(Pid, {?MSG_PRV, ?LINKED_PID_EXIT_REASON})
        end,
        DEP
    ),
    LP = LinkedPids -- DEP,
    lists:foreach(fun(Pid) when is_pid(Pid) -> exit(Pid, ?LINKED_PID_EXIT_REASON) end, LP),
    wait_exits(LP),
    StateData#state{linked_pids = [], direct_execution_pids = []}.

wait_exits([P | TPids] = Pids) ->
    case erlang:is_process_alive(P) of
        true -> wait_exits(Pids);
        false -> wait_exits(TPids)
    end;
wait_exits([]) ->
    ok.

cleanup(StateData) ->
    stop_ets(kill_pids(StateData)).

%% -------------------------------------------------------------------------------------------------
%% telemetry

ev_origin() -> ?EVENT_ORIGIN.

ev_metadata(StateData) ->
    Metadata = StateData#state.ev_metadata,
    case Metadata of
        #{closing_state := _} -> Metadata#{workflow_info => get_workflow_info(StateData)};
        #{} -> Metadata
    end.
