-module(temporal_sdk_api_command).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    awaitable_command_count/1,
    is_event_commanded/2,

    complete_workflow_execution_command/2,
    cancel_workflow_execution_command/2,
    fail_workflow_execution_command/2,
    continue_as_new_workflow_command/2,

    schedule_activity_task_command/1,
    request_cancel_activity_task_command/1,
    record_marker_command/1,
    modify_workflow_properties_command/1,
    start_timer_command/1,
    cancel_timer_command/1,

    start_child_workflow_command/1,

    schedule_nexus_operation/2,

    schedule_activity_task_command_to_task/2
]).

-include("proto.hrl").

%% https://docs.temporal.io/references/commands
%% Awaitable commands:
%%   StartChildWorkflowExecution
%%   SignalExternalWorkflowExecution
%%   RequestCancelExternalWorkflowExecution
%%   ScheduleActivityTask
%%   StartTimer
%%   ScheduleNexusOperation
-define(AWAITABLE_COMMANDS, [
    'COMMAND_TYPE_SCHEDULE_ACTIVITY_TASK',
    'COMMAND_TYPE_START_TIMER',
    'COMMAND_TYPE_START_CHILD_WORKFLOW_EXECUTION',
    'COMMAND_TYPE_SCHEDULE_NEXUS_OPERATION',
    'COMMAND_TYPE_SIGNAL_EXTERNAL_WORKFLOW_EXECUTION',
    'COMMAND_TYPE_REQUEST_CANCEL_EXTERNAL_WORKFLOW_EXECUTION'
]).

-define(COMMANDED_EVENTS, [
    'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED',
    'EVENT_TYPE_ACTIVITY_TASK_CANCEL_REQUESTED',

    'EVENT_TYPE_MARKER_RECORDED',

    'EVENT_TYPE_TIMER_STARTED',
    'EVENT_TYPE_TIMER_CANCELED',

    'EVENT_TYPE_START_CHILD_WORKFLOW_EXECUTION_INITIATED',
    'EVENT_TYPE_START_CHILD_WORKFLOW_EXECUTION_FAILED',

    'EVENT_TYPE_NEXUS_OPERATION_SCHEDULED',
    'EVENT_TYPE_NEXUS_OPERATION_CANCEL_REQUESTED',

    'EVENT_TYPE_EXTERNAL_WORKFLOW_EXECUTION_CANCEL_REQUESTED',
    'EVENT_TYPE_WORKFLOW_EXECUTION_COMPLETED',
    'EVENT_TYPE_WORKFLOW_EXECUTION_CANCELED',
    'EVENT_TYPE_WORKFLOW_EXECUTION_FAILED',
    'EVENT_TYPE_WORKFLOW_EXECUTION_CONTINUED_AS_NEW'
]).

-type command() :: ?TEMPORAL_SPEC:'temporal.api.command.v1.Command'().
-export_type([command/0]).

%% Deadlocking cancelation commands are counted with temporal_sdk_executor_workflow:do_cmds/5.
-spec awaitable_command_count(IndexCommand :: temporal_sdk_workflow:index_command()) ->
    0 | 1.
awaitable_command_count({_Index, #{command_type := CommandType}}) ->
    case lists:member(CommandType, ?AWAITABLE_COMMANDS) of
        true -> 1;
        false -> 0
    end;
awaitable_command_count({_Index, _Command}) ->
    0.

-spec is_event_commanded(
    EventType :: ?TEMPORAL_SPEC:'temporal.api.enums.v1.EventType'(),
    EventAttributes :: map()
) -> boolean().
is_event_commanded('EVENT_TYPE_MARKER_RECORDED', #{
    details := #{"type" := #{payloads := [#{data := Type}]}}
}) when Type =:= "message"; Type =:= ~"message" ->
    false;
is_event_commanded('EVENT_TYPE_MARKER_RECORDED', #{
    details := #{~"type" := #{payloads := [#{data := Type}]}}
}) when Type =:= "message"; Type =:= ~"message" ->
    false;
is_event_commanded(EventType, _EventAttributes) ->
    lists:member(EventType, ?COMMANDED_EVENTS).

-spec complete_workflow_execution_command(
    ApiContext :: temporal_sdk_api:context(),
    Result :: temporal_sdk:term_to_payloads()
) -> command().
complete_workflow_execution_command(ApiContext, Result) ->
    MsgName = 'temporal.api.command.v1.CompleteWorkflowExecutionCommandAttributes',
    #{
        command_type => 'COMMAND_TYPE_COMPLETE_WORKFLOW_EXECUTION',
        attributes =>
            {complete_workflow_execution_command_attributes, #{
                result =>
                    temporal_sdk_api:map_to_payloads(ApiContext, MsgName, result, Result)
            }}
    }.

-spec cancel_workflow_execution_command(
    ApiContext :: temporal_sdk_api:context(),
    Details :: temporal_sdk:term_to_payloads()
) -> command().
cancel_workflow_execution_command(ApiContext, Details) ->
    MsgName = 'temporal.api.command.v1.CancelWorkflowExecutionCommandAttributes',
    #{
        command_type => 'COMMAND_TYPE_CANCEL_WORKFLOW_EXECUTION',
        attributes =>
            {cancel_workflow_execution_command_attributes, #{
                details =>
                    temporal_sdk_api:map_to_payloads(ApiContext, MsgName, details, Details)
            }}
    }.

-spec fail_workflow_execution_command(
    ApiContext :: temporal_sdk_api:context(),
    Failure :: ?TEMPORAL_SPEC:'temporal.api.failure.v1.Failure'()
) -> command().
fail_workflow_execution_command(_ApiContext, Failure) ->
    #{
        command_type => 'COMMAND_TYPE_FAIL_WORKFLOW_EXECUTION',
        attributes => {fail_workflow_execution_command_attributes, #{failure => Failure}}
    }.

-spec continue_as_new_workflow_command(
    ApiContext :: temporal_sdk_api:context(),
    Attr :: ?TEMPORAL_SPEC:'temporal.api.command.v1.ContinueAsNewWorkflowExecutionCommandAttributes'()
) -> command().
continue_as_new_workflow_command(_ApiContext, Attr) ->
    #{
        command_type => 'COMMAND_TYPE_CONTINUE_AS_NEW_WORKFLOW_EXECUTION',
        attributes => {continue_as_new_workflow_execution_command_attributes, Attr}
    }.

-spec schedule_activity_task_command(
    Attr :: ?TEMPORAL_SPEC:'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'()
) -> command().
schedule_activity_task_command(Attr) ->
    #{
        command_type => 'COMMAND_TYPE_SCHEDULE_ACTIVITY_TASK',
        attributes => {schedule_activity_task_command_attributes, Attr}
    }.

-spec request_cancel_activity_task_command(
    Attr :: ?TEMPORAL_SPEC:'temporal.api.command.v1.RequestCancelActivityTaskCommandAttributes'()
) -> command().
request_cancel_activity_task_command(Attr) ->
    #{
        command_type => 'COMMAND_TYPE_REQUEST_CANCEL_ACTIVITY_TASK',
        attributes => {request_cancel_activity_task_command_attributes, Attr}
    }.

-spec record_marker_command(
    Attr :: ?TEMPORAL_SPEC:'temporal.api.command.v1.RecordMarkerCommandAttributes'()
) -> command().
record_marker_command(Attr) ->
    #{
        command_type => 'COMMAND_TYPE_RECORD_MARKER',
        attributes => {record_marker_command_attributes, Attr}
    }.

-spec modify_workflow_properties_command(
    Attr :: ?TEMPORAL_SPEC:'temporal.api.command.v1.ModifyWorkflowPropertiesCommandAttributes'()
) -> command().
modify_workflow_properties_command(Attr) ->
    #{
        command_type => 'COMMAND_TYPE_MODIFY_WORKFLOW_PROPERTIES',
        attributes => {modify_workflow_properties_command_attributes, Attr}
    }.

-spec start_timer_command(
    Attr :: ?TEMPORAL_SPEC:'temporal.api.command.v1.StartTimerCommandAttributes'()
) -> command().
start_timer_command(Attr) ->
    #{
        command_type => 'COMMAND_TYPE_START_TIMER',
        attributes => {start_timer_command_attributes, Attr}
    }.

-spec cancel_timer_command(IndexKey :: temporal_sdk_workflow:timer_index_key()) -> command().
cancel_timer_command({timer, TimerId}) ->
    #{
        command_type => 'COMMAND_TYPE_CANCEL_TIMER',
        attributes => {cancel_timer_command_attributes, #{timer_id => TimerId}}
    }.

-spec start_child_workflow_command(
    Attr :: ?TEMPORAL_SPEC:'temporal.api.command.v1.StartChildWorkflowExecutionCommandAttributes'()
) ->
    command().
start_child_workflow_command(Attr) ->
    #{
        command_type => 'COMMAND_TYPE_START_CHILD_WORKFLOW_EXECUTION',
        attributes => {start_child_workflow_execution_command_attributes, Attr}
    }.

-spec schedule_nexus_operation(
    IndexKey :: temporal_sdk_workflow:nexus_index_key(),
    Attributes :: ?TEMPORAL_SPEC:'temporal.api.command.v1.ScheduleNexusOperationCommandAttributes'()
) -> command().
schedule_nexus_operation({nexus, Endpoint, Service, Operation}, Attributes) ->
    Attr = Attributes#{endpoint => Endpoint, service => Service, operation => Operation},
    #{
        command_type => 'COMMAND_TYPE_SCHEDULE_NEXUS_OPERATION',
        attributes => {schedule_nexus_operation_command_attributes, Attr}
    }.

-spec schedule_activity_task_command_to_task(
    ActivityIdxCmd :: {
        {temporal_sdk_workflow:activity(), temporal_sdk_workflow:activity_data()}, command()
    },
    ApiContext :: temporal_sdk_api:context()
) -> temporal_sdk_activity:task().
schedule_activity_task_command_to_task(
    {{{activity, _Id}, #{state := cmd, direct_execution := true}}, Cmd}, ApiContext
) ->
    #{
        attributes := {schedule_activity_task_command_attributes, CmdTask},
        command_type := 'COMMAND_TYPE_SCHEDULE_ACTIVITY_TASK'
    } = Cmd,
    #{
        worker_opts := #{namespace := WorkflowNamespace},
        task_opts := #{workflow_id := WorkflowId, run_id := RunId, workflow_type := WorkflowType}
    } = ApiContext,

    Timeout = temporal_sdk_utils_time:msec_to_protobuf(0),
    Now = temporal_sdk_utils_time:system_time_protobuf(),
    T0 = maps:without([request_eager_execution, task_queue], CmdTask),
    T1 = T0#{
        workflow_type => #{name => WorkflowType},
        workflow_execution => #{workflow_id => WorkflowId, run_id => RunId},
        workflow_namespace => WorkflowNamespace
    },
    T2 = temporal_sdk_utils_maps:store(heartbeat_timeout, T1, Timeout),
    T3 = temporal_sdk_utils_maps:store(start_to_close_timeout, T2, Timeout),
    T4 = temporal_sdk_utils_maps:store(schedule_to_close_timeout, T3, Timeout),
    T5 = temporal_sdk_utils_maps:store(scheduled_time, T4, Now),
    T6 = temporal_sdk_utils_maps:store(started_time, T5, Now),
    T7 = temporal_sdk_utils_maps:store(current_attempt_scheduled_time, T6, Now),
    T8 = temporal_sdk_utils_maps:store(attempt, T7, 1),
    temporal_sdk_utils_maps:store(task_token, T8, undefined).
