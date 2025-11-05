-module(temporal_sdk_api_activity_task).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    input/2,
    task_token/1,
    workflow_namespace/1,
    workflow_type_name/1,
    workflow_execution/1,
    workflow_execution_workflow_id/1,
    workflow_execution_run_id/1,
    activity_type_name/1,
    activity_id/1,
    attempt/1,
    schedule_to_close_timeout/1,
    start_to_close_timeout/1,
    heartbeat_timeout/1
]).

-include("proto.hrl").

-spec input(ApiCtx :: temporal_sdk_api:context(), Task :: temporal_sdk_activity:task()) ->
    temporal_sdk:term_from_payloads().
input(ApiCtx, Task) ->
    temporal_sdk_api:map_from_payloads(
        ApiCtx,
        'temporal.api.workflowservice.v1.PollActivityTaskQueueResponse',
        input,
        maps:get(input, Task, #{payloads => []})
    ).

-spec task_token(temporal_sdk_activity:task()) -> iodata().
task_token(#{task_token := TaskToken}) -> TaskToken.

-spec workflow_namespace(temporal_sdk_activity:task()) -> unicode:chardata().
workflow_namespace(#{workflow_namespace := WorkflowNamespace}) -> WorkflowNamespace.

-spec workflow_type_name(temporal_sdk_activity:task()) -> unicode:chardata().
workflow_type_name(#{workflow_type := #{name := Name}}) -> Name.

-spec workflow_execution(temporal_sdk_activity:task()) ->
    ?TEMPORAL_SPEC:'temporal.api.common.v1.WorkflowExecution'().
workflow_execution(#{workflow_execution := V}) -> V.

-spec workflow_execution_workflow_id(temporal_sdk_activity:task()) -> unicode:chardata().
workflow_execution_workflow_id(#{workflow_execution := #{workflow_id := V}}) -> V.

-spec workflow_execution_run_id(temporal_sdk_activity:task()) -> unicode:chardata().
workflow_execution_run_id(#{workflow_execution := #{run_id := V}}) -> V.

-spec activity_type_name(temporal_sdk_activity:task()) -> unicode:chardata().
activity_type_name(#{activity_type := #{name := Name}}) -> Name.

-spec activity_id(temporal_sdk_activity:task()) -> unicode:chardata().
activity_id(#{activity_id := ActivityId}) -> ActivityId.

-spec attempt(temporal_sdk_activity:task()) -> pos_integer().
attempt(#{attempt := Attempt}) -> Attempt.

-spec schedule_to_close_timeout(temporal_sdk_activity:task()) -> erlang:timeout().
schedule_to_close_timeout(Task) ->
    case Task of
        #{schedule_to_close_timeout := Timeout} ->
            temporal_sdk_utils_time:protobuf_to_msec(Timeout);
        #{} ->
            infinity
    end.

-spec start_to_close_timeout(temporal_sdk_activity:task()) -> erlang:timeout().
start_to_close_timeout(Task) ->
    case Task of
        #{start_to_close_timeout := Timeout} -> temporal_sdk_utils_time:protobuf_to_msec(Timeout);
        #{} -> infinity
    end.

-spec heartbeat_timeout(temporal_sdk_activity:task()) -> erlang:timeout().
heartbeat_timeout(Task) ->
    case Task of
        #{heartbeat_timeout := Timeout} -> temporal_sdk_utils_time:protobuf_to_msec(Timeout);
        #{} -> infinity
    end.
