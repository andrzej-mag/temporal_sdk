-module(temporal_sdk_api_history).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    workflow_execution_status/1,
    workflow_execution_result/2
]).

-include("proto.hrl").

-spec workflow_execution_status(
    ExecutionStatus :: ?TEMPORAL_SPEC:'temporal.api.enums.v1.WorkflowExecutionStatus'() | integer()
) ->
    completed
    | failed
    | timed_out
    | terminated
    | canceled
    | continued_as_new
    | unspecified
    | running.
workflow_execution_status('WORKFLOW_EXECUTION_STATUS_COMPLETED') -> completed;
workflow_execution_status('WORKFLOW_EXECUTION_STATUS_FAILED') -> failed;
workflow_execution_status('WORKFLOW_EXECUTION_STATUS_TIMED_OUT') -> timed_out;
workflow_execution_status('WORKFLOW_EXECUTION_STATUS_TERMINATED') -> terminated;
workflow_execution_status('WORKFLOW_EXECUTION_STATUS_CANCELED') -> canceled;
workflow_execution_status('WORKFLOW_EXECUTION_STATUS_CONTINUED_AS_NEW') -> continued_as_new;
workflow_execution_status('WORKFLOW_EXECUTION_STATUS_UNSPECIFIED') -> unspecified;
workflow_execution_status('WORKFLOW_EXECUTION_STATUS_RUNNING') -> running;
workflow_execution_status(0) -> unspecified;
workflow_execution_status(1) -> running;
workflow_execution_status(2) -> completed;
workflow_execution_status(3) -> failed;
workflow_execution_status(4) -> canceled;
workflow_execution_status(5) -> terminated;
workflow_execution_status(6) -> continued_as_new;
workflow_execution_status(7) -> timed_out.

-spec workflow_execution_result(
    Event :: ?TEMPORAL_SPEC:'temporal.api.history.v1.HistoryEvent'(),
    ApiContext :: temporal_sdk_api:context()
) -> {ok, temporal_sdk:workflow_result()} | {error, Reason :: map()}.
workflow_execution_result(
    #{attributes := {workflow_execution_completed_event_attributes, Attr}}, ApiCtx
) ->
    MN = 'temporal.api.history.v1.WorkflowExecutionCompletedEventAttributes',
    {ok, {completed, temporal_sdk_api_common:t2e(MN, Attr, ApiCtx)}};
workflow_execution_result(
    #{attributes := {workflow_execution_failed_event_attributes, Attr}}, ApiCtx
) ->
    MN = 'temporal.api.history.v1.WorkflowExecutionFailedEventAttributes',
    {ok, {failed, temporal_sdk_api_common:t2e(MN, Attr, ApiCtx)}};
workflow_execution_result(
    #{attributes := {workflow_execution_timed_out_event_attributes, Attr}}, ApiCtx
) ->
    MN = 'temporal.api.history.v1.WorkflowExecutionTimedOutEventAttributes',
    {ok, {timed_out, temporal_sdk_api_common:t2e(MN, Attr, ApiCtx)}};
workflow_execution_result(
    #{attributes := {workflow_execution_terminated_event_attributes, Attr}}, ApiCtx
) ->
    MN = 'temporal.api.history.v1.WorkflowExecutionTerminatedEventAttributes',
    {ok, {terminated, temporal_sdk_api_common:t2e(MN, Attr, ApiCtx)}};
workflow_execution_result(
    #{attributes := {workflow_execution_canceled_event_attributes, Attr}}, ApiCtx
) ->
    MN = 'temporal.api.history.v1.WorkflowExecutionCanceledEventAttributes',
    {ok, {canceled, temporal_sdk_api_common:t2e(MN, Attr, ApiCtx)}};
workflow_execution_result(
    #{attributes := {workflow_execution_continued_as_new_event_attributes, Attr}}, ApiCtx
) ->
    MN = 'temporal.api.history.v1.WorkflowExecutionContinuedAsNewEventAttributes',
    {ok, {continued_as_new, temporal_sdk_api_common:t2e(MN, Attr, ApiCtx)}};
workflow_execution_result(UnrecognizedEvent, _ApiCtx) ->
    {error, #{
        reason => "Unrecognized workflow closing event.", unrecognized_event => UnrecognizedEvent
    }}.
