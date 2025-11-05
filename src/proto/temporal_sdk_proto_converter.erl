%% Automatically generated, do not edit.
%% gpb library version:          4.21.5
%% temporal_sdk_proto version:   0.1.0
%% Temporal API version tag:     v1.56.0-1-g831691d

-module(temporal_sdk_proto_converter).

-behaviour(temporal_sdk_grpc_converter).

% elp:ignore W0012 W0040
-moduledoc false.

-export([convert/5, convert/6]).

-import(temporal_sdk_utils_proto_converter, [convert_paths/7, convert_payload/4]).

convert(MsgName, Msg, Cluster, RequestInfo, {DefaultCodecs, CustomCodecs}) ->
    convert(MsgName, Msg, Cluster, RequestInfo, CustomCodecs, DefaultCodecs);
convert(MsgName, Msg, Cluster, RequestInfo, DefaultCodecs) when is_list(DefaultCodecs) ->
    convert(MsgName, Msg, Cluster, RequestInfo, [], DefaultCodecs).

convert('temporal.api.batch.v1.BatchOperationReset' = N, M, Cl, RI, CC, C) ->
    P = [{post_reset_operations, {repeated, 'temporal.api.workflow.v1.PostResetOperation'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.batch.v1.BatchOperationSignal' = N, M, Cl, RI, CC, C) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {header, {optional, 'temporal.api.common.v1.Header'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.batch.v1.BatchOperationTermination' = N, M, Cl, RI, CC, C) ->
    P = [{details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.command.v1.CancelWorkflowExecutionCommandAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.command.v1.Command' = N, M, Cl, RI, CC, C) ->
    P = [
        {user_metadata, {optional, 'temporal.api.sdk.v1.UserMetadata'}},
        {
            {attributes, schedule_nexus_operation_command_attributes},
            {optional, 'temporal.api.command.v1.ScheduleNexusOperationCommandAttributes'}
        },
        {
            {attributes, complete_workflow_execution_command_attributes},
            {optional, 'temporal.api.command.v1.CompleteWorkflowExecutionCommandAttributes'}
        },
        {
            {attributes, record_marker_command_attributes},
            {optional, 'temporal.api.command.v1.RecordMarkerCommandAttributes'}
        },
        {
            {attributes, cancel_workflow_execution_command_attributes},
            {optional, 'temporal.api.command.v1.CancelWorkflowExecutionCommandAttributes'}
        },
        {
            {attributes, schedule_activity_task_command_attributes},
            {optional, 'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'}
        },
        {
            {attributes, start_child_workflow_execution_command_attributes},
            {optional, 'temporal.api.command.v1.StartChildWorkflowExecutionCommandAttributes'}
        },
        {
            {attributes, signal_external_workflow_execution_command_attributes},
            {optional, 'temporal.api.command.v1.SignalExternalWorkflowExecutionCommandAttributes'}
        },
        {
            {attributes, continue_as_new_workflow_execution_command_attributes},
            {optional, 'temporal.api.command.v1.ContinueAsNewWorkflowExecutionCommandAttributes'}
        },
        {
            {attributes, modify_workflow_properties_command_attributes},
            {optional, 'temporal.api.command.v1.ModifyWorkflowPropertiesCommandAttributes'}
        },
        {
            {attributes, upsert_workflow_search_attributes_command_attributes},
            {optional, 'temporal.api.command.v1.UpsertWorkflowSearchAttributesCommandAttributes'}
        },
        {
            {attributes, fail_workflow_execution_command_attributes},
            {optional, 'temporal.api.command.v1.FailWorkflowExecutionCommandAttributes'}
        }
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.command.v1.CompleteWorkflowExecutionCommandAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{result, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.command.v1.ContinueAsNewWorkflowExecutionCommandAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {last_completion_result, {optional, 'temporal.api.common.v1.Payloads'}},
        {memo, {optional, 'temporal.api.common.v1.Memo'}},
        {search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}},
        {header, {optional, 'temporal.api.common.v1.Header'}},
        {failure, {optional, 'temporal.api.failure.v1.Failure'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.command.v1.FailWorkflowExecutionCommandAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.command.v1.ModifyWorkflowPropertiesCommandAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{upserted_memo, {optional, 'temporal.api.common.v1.Memo'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.command.v1.RecordMarkerCommandAttributes' = N, M, Cl, RI, CC, C) ->
    P = [
        {details, {map_string, 'temporal.api.common.v1.Payloads'}},
        {header, {optional, 'temporal.api.common.v1.Header'}},
        {failure, {optional, 'temporal.api.failure.v1.Failure'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.command.v1.ScheduleActivityTaskCommandAttributes' = N, M, Cl, RI, CC, C) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {header, {optional, 'temporal.api.common.v1.Header'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.command.v1.ScheduleNexusOperationCommandAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{input, {optional, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.command.v1.SignalExternalWorkflowExecutionCommandAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {header, {optional, 'temporal.api.common.v1.Header'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.command.v1.StartChildWorkflowExecutionCommandAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {memo, {optional, 'temporal.api.common.v1.Memo'}},
        {search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}},
        {header, {optional, 'temporal.api.common.v1.Header'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.command.v1.UpsertWorkflowSearchAttributesCommandAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [{search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.common.v1.Header' = N, M, Cl, RI, CC, C) ->
    P = [{fields, {map_string, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.common.v1.Memo' = N, M, Cl, RI, CC, C) ->
    P = [{fields, {map_string, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.common.v1.Payloads' = N, M, Cl, RI, CC, C) ->
    P = [{payloads, {repeated, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.common.v1.SearchAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{indexed_fields, {map_string, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.deployment.v1.DeploymentInfo' = N, M, Cl, RI, CC, C) ->
    P = [{metadata, {map_string, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.deployment.v1.UpdateDeploymentMetadata' = N, M, Cl, RI, CC, C) ->
    P = [{upsert_entries, {map_string, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.deployment.v1.VersionMetadata' = N, M, Cl, RI, CC, C) ->
    P = [{entries, {map_string, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.deployment.v1.WorkerDeploymentVersionInfo' = N, M, Cl, RI, CC, C) ->
    P = [{metadata, {optional, 'temporal.api.deployment.v1.VersionMetadata'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.failure.v1.ApplicationFailureInfo' = N, M, Cl, RI, CC, C) ->
    P = [{details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.failure.v1.CanceledFailureInfo' = N, M, Cl, RI, CC, C) ->
    P = [{details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.failure.v1.Failure' = N, M, Cl, RI, CC, C) ->
    P = [
        {encoded_attributes, {optional, 'temporal.api.common.v1.Payload'}},
        {cause, {optional, 'temporal.api.failure.v1.Failure'}},
        {
            {failure_info, canceled_failure_info},
            {optional, 'temporal.api.failure.v1.CanceledFailureInfo'}
        },
        {
            {failure_info, application_failure_info},
            {optional, 'temporal.api.failure.v1.ApplicationFailureInfo'}
        },
        {
            {failure_info, reset_workflow_failure_info},
            {optional, 'temporal.api.failure.v1.ResetWorkflowFailureInfo'}
        },
        {
            {failure_info, timeout_failure_info},
            {optional, 'temporal.api.failure.v1.TimeoutFailureInfo'}
        }
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.failure.v1.ResetWorkflowFailureInfo' = N, M, Cl, RI, CC, C) ->
    P = [{last_heartbeat_details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.failure.v1.TimeoutFailureInfo' = N, M, Cl, RI, CC, C) ->
    P = [{last_heartbeat_details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.ActivityTaskCanceledEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.ActivityTaskCompletedEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{result, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.ActivityTaskFailedEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.ActivityTaskScheduledEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {header, {optional, 'temporal.api.common.v1.Header'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.ActivityTaskStartedEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{last_failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.ActivityTaskTimedOutEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.ChildWorkflowExecutionCanceledEventAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [{details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.ChildWorkflowExecutionCompletedEventAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [{result, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.ChildWorkflowExecutionFailedEventAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [{failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.ChildWorkflowExecutionStartedEventAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [{header, {optional, 'temporal.api.common.v1.Header'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.History' = N, M, Cl, RI, CC, C) ->
    P = [{events, {repeated, 'temporal.api.history.v1.HistoryEvent'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.HistoryEvent' = N, M, Cl, RI, CC, C) ->
    P = [
        {user_metadata, {optional, 'temporal.api.sdk.v1.UserMetadata'}},
        {
            {attributes, nexus_operation_completed_event_attributes},
            {optional, 'temporal.api.history.v1.NexusOperationCompletedEventAttributes'}
        },
        {
            {attributes, nexus_operation_scheduled_event_attributes},
            {optional, 'temporal.api.history.v1.NexusOperationScheduledEventAttributes'}
        },
        {
            {attributes, child_workflow_execution_completed_event_attributes},
            {optional, 'temporal.api.history.v1.ChildWorkflowExecutionCompletedEventAttributes'}
        },
        {
            {attributes, marker_recorded_event_attributes},
            {optional, 'temporal.api.history.v1.MarkerRecordedEventAttributes'}
        },
        {
            {attributes, activity_task_completed_event_attributes},
            {optional, 'temporal.api.history.v1.ActivityTaskCompletedEventAttributes'}
        },
        {
            {attributes, workflow_execution_completed_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionCompletedEventAttributes'}
        },
        {
            {attributes, child_workflow_execution_canceled_event_attributes},
            {optional, 'temporal.api.history.v1.ChildWorkflowExecutionCanceledEventAttributes'}
        },
        {
            {attributes, activity_task_scheduled_event_attributes},
            {optional, 'temporal.api.history.v1.ActivityTaskScheduledEventAttributes'}
        },
        {
            {attributes, workflow_execution_started_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'}
        },
        {
            {attributes, workflow_execution_canceled_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionCanceledEventAttributes'}
        },
        {
            {attributes, workflow_execution_terminated_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionTerminatedEventAttributes'}
        },
        {
            {attributes, start_child_workflow_execution_initiated_event_attributes},
            {optional,
                'temporal.api.history.v1.StartChildWorkflowExecutionInitiatedEventAttributes'}
        },
        {
            {attributes, workflow_execution_continued_as_new_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionContinuedAsNewEventAttributes'}
        },
        {
            {attributes, activity_task_canceled_event_attributes},
            {optional, 'temporal.api.history.v1.ActivityTaskCanceledEventAttributes'}
        },
        {
            {attributes, workflow_execution_signaled_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionSignaledEventAttributes'}
        },
        {
            {attributes, signal_external_workflow_execution_initiated_event_attributes},
            {optional,
                'temporal.api.history.v1.SignalExternalWorkflowExecutionInitiatedEventAttributes'}
        },
        {
            {attributes, workflow_properties_modified_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowPropertiesModifiedEventAttributes'}
        },
        {
            {attributes, workflow_properties_modified_externally_event_attributes},
            {optional,
                'temporal.api.history.v1.WorkflowPropertiesModifiedExternallyEventAttributes'}
        },
        {
            {attributes, upsert_workflow_search_attributes_event_attributes},
            {optional, 'temporal.api.history.v1.UpsertWorkflowSearchAttributesEventAttributes'}
        },
        {
            {attributes, child_workflow_execution_started_event_attributes},
            {optional, 'temporal.api.history.v1.ChildWorkflowExecutionStartedEventAttributes'}
        },
        {
            {attributes, activity_task_failed_event_attributes},
            {optional, 'temporal.api.history.v1.ActivityTaskFailedEventAttributes'}
        },
        {
            {attributes, activity_task_started_event_attributes},
            {optional, 'temporal.api.history.v1.ActivityTaskStartedEventAttributes'}
        },
        {
            {attributes, activity_task_timed_out_event_attributes},
            {optional, 'temporal.api.history.v1.ActivityTaskTimedOutEventAttributes'}
        },
        {
            {attributes, child_workflow_execution_failed_event_attributes},
            {optional, 'temporal.api.history.v1.ChildWorkflowExecutionFailedEventAttributes'}
        },
        {
            {attributes, nexus_operation_cancel_request_failed_event_attributes},
            {optional, 'temporal.api.history.v1.NexusOperationCancelRequestFailedEventAttributes'}
        },
        {
            {attributes, nexus_operation_canceled_event_attributes},
            {optional, 'temporal.api.history.v1.NexusOperationCanceledEventAttributes'}
        },
        {
            {attributes, nexus_operation_failed_event_attributes},
            {optional, 'temporal.api.history.v1.NexusOperationFailedEventAttributes'}
        },
        {
            {attributes, nexus_operation_timed_out_event_attributes},
            {optional, 'temporal.api.history.v1.NexusOperationTimedOutEventAttributes'}
        },
        {
            {attributes, workflow_execution_failed_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionFailedEventAttributes'}
        },
        {
            {attributes, workflow_execution_update_rejected_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionUpdateRejectedEventAttributes'}
        },
        {
            {attributes, workflow_task_failed_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowTaskFailedEventAttributes'}
        },
        {
            {attributes, workflow_execution_update_completed_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionUpdateCompletedEventAttributes'}
        },
        {
            {attributes, workflow_execution_update_accepted_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionUpdateAcceptedEventAttributes'}
        },
        {
            {attributes, workflow_execution_update_admitted_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionUpdateAdmittedEventAttributes'}
        }
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.MarkerRecordedEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [
        {details, {map_string, 'temporal.api.common.v1.Payloads'}},
        {header, {optional, 'temporal.api.common.v1.Header'}},
        {failure, {optional, 'temporal.api.failure.v1.Failure'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.NexusOperationCancelRequestFailedEventAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [{failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.NexusOperationCanceledEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.NexusOperationCompletedEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{result, {optional, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.NexusOperationFailedEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.NexusOperationScheduledEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{input, {optional, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.NexusOperationTimedOutEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.SignalExternalWorkflowExecutionInitiatedEventAttributes' = N,
    M,
    Cl,
    RI,
    CC,
    C
) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {header, {optional, 'temporal.api.common.v1.Header'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.StartChildWorkflowExecutionInitiatedEventAttributes' = N,
    M,
    Cl,
    RI,
    CC,
    C
) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {memo, {optional, 'temporal.api.common.v1.Memo'}},
        {search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}},
        {header, {optional, 'temporal.api.common.v1.Header'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.UpsertWorkflowSearchAttributesEventAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [{search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.WorkflowExecutionCanceledEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.WorkflowExecutionCompletedEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{result, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.WorkflowExecutionContinuedAsNewEventAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {last_completion_result, {optional, 'temporal.api.common.v1.Payloads'}},
        {memo, {optional, 'temporal.api.common.v1.Memo'}},
        {search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}},
        {header, {optional, 'temporal.api.common.v1.Header'}},
        {failure, {optional, 'temporal.api.failure.v1.Failure'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.WorkflowExecutionFailedEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.WorkflowExecutionSignaledEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {header, {optional, 'temporal.api.common.v1.Header'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.WorkflowExecutionStartedEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {last_completion_result, {optional, 'temporal.api.common.v1.Payloads'}},
        {memo, {optional, 'temporal.api.common.v1.Memo'}},
        {search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}},
        {header, {optional, 'temporal.api.common.v1.Header'}},
        {continued_failure, {optional, 'temporal.api.failure.v1.Failure'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.WorkflowExecutionTerminatedEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.WorkflowExecutionUpdateAcceptedEventAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [{accepted_request, {optional, 'temporal.api.update.v1.Request'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.WorkflowExecutionUpdateAdmittedEventAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [{request, {optional, 'temporal.api.update.v1.Request'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.WorkflowExecutionUpdateCompletedEventAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [{outcome, {optional, 'temporal.api.update.v1.Outcome'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.WorkflowExecutionUpdateRejectedEventAttributes' = N, M, Cl, RI, CC, C
) ->
    P = [
        {failure, {optional, 'temporal.api.failure.v1.Failure'}},
        {rejected_request, {optional, 'temporal.api.update.v1.Request'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.WorkflowPropertiesModifiedEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{upserted_memo, {optional, 'temporal.api.common.v1.Memo'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.history.v1.WorkflowPropertiesModifiedExternallyEventAttributes' = N,
    M,
    Cl,
    RI,
    CC,
    C
) ->
    P = [{upserted_memo, {optional, 'temporal.api.common.v1.Memo'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.history.v1.WorkflowTaskFailedEventAttributes' = N, M, Cl, RI, CC, C) ->
    P = [{failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.nexus.v1.Endpoint' = N, M, Cl, RI, CC, C) ->
    P = [{spec, {optional, 'temporal.api.nexus.v1.EndpointSpec'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.nexus.v1.EndpointSpec' = N, M, Cl, RI, CC, C) ->
    P = [{description, {optional, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.nexus.v1.Request' = N, M, Cl, RI, CC, C) ->
    P = [{{variant, start_operation}, {optional, 'temporal.api.nexus.v1.StartOperationRequest'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.nexus.v1.Response' = N, M, Cl, RI, CC, C) ->
    P = [{{variant, start_operation}, {optional, 'temporal.api.nexus.v1.StartOperationResponse'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.nexus.v1.StartOperationRequest' = N, M, Cl, RI, CC, C) ->
    P = [{payload, {optional, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.nexus.v1.StartOperationResponse' = N, M, Cl, RI, CC, C) ->
    P = [
        {{variant, sync_success}, {optional, 'temporal.api.nexus.v1.StartOperationResponse.Sync'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.nexus.v1.StartOperationResponse.Sync' = N, M, Cl, RI, CC, C) ->
    P = [{payload, {optional, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.operatorservice.v1.CreateNexusEndpointRequest' = N, M, Cl, RI, CC, C) ->
    P = [{spec, {optional, 'temporal.api.nexus.v1.EndpointSpec'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.operatorservice.v1.CreateNexusEndpointResponse' = N, M, Cl, RI, CC, C) ->
    P = [{endpoint, {optional, 'temporal.api.nexus.v1.Endpoint'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.operatorservice.v1.GetNexusEndpointResponse' = N, M, Cl, RI, CC, C) ->
    P = [{endpoint, {optional, 'temporal.api.nexus.v1.Endpoint'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.operatorservice.v1.ListNexusEndpointsResponse' = N, M, Cl, RI, CC, C) ->
    P = [{endpoints, {repeated, 'temporal.api.nexus.v1.Endpoint'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.operatorservice.v1.UpdateNexusEndpointRequest' = N, M, Cl, RI, CC, C) ->
    P = [{spec, {optional, 'temporal.api.nexus.v1.EndpointSpec'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.operatorservice.v1.UpdateNexusEndpointResponse' = N, M, Cl, RI, CC, C) ->
    P = [{endpoint, {optional, 'temporal.api.nexus.v1.Endpoint'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.query.v1.WorkflowQuery' = N, M, Cl, RI, CC, C) ->
    P = [
        {query_args, {optional, 'temporal.api.common.v1.Payloads'}},
        {header, {optional, 'temporal.api.common.v1.Header'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.query.v1.WorkflowQueryResult' = N, M, Cl, RI, CC, C) ->
    P = [
        {answer, {optional, 'temporal.api.common.v1.Payloads'}},
        {failure, {optional, 'temporal.api.failure.v1.Failure'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.schedule.v1.Schedule' = N, M, Cl, RI, CC, C) ->
    P = [{action, {optional, 'temporal.api.schedule.v1.ScheduleAction'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.schedule.v1.ScheduleAction' = N, M, Cl, RI, CC, C) ->
    P = [
        {{action, start_workflow}, {optional, 'temporal.api.workflow.v1.NewWorkflowExecutionInfo'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.schedule.v1.ScheduleListEntry' = N, M, Cl, RI, CC, C) ->
    P = [
        {memo, {optional, 'temporal.api.common.v1.Memo'}},
        {search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.sdk.v1.UserMetadata' = N, M, Cl, RI, CC, C) ->
    P = [
        {summary, {optional, 'temporal.api.common.v1.Payload'}},
        {details, {optional, 'temporal.api.common.v1.Payload'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.update.v1.Acceptance' = N, M, Cl, RI, CC, C) ->
    P = [{accepted_request, {optional, 'temporal.api.update.v1.Request'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.update.v1.Input' = N, M, Cl, RI, CC, C) ->
    P = [
        {args, {optional, 'temporal.api.common.v1.Payloads'}},
        {header, {optional, 'temporal.api.common.v1.Header'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.update.v1.Outcome' = N, M, Cl, RI, CC, C) ->
    P = [
        {{value, success}, {optional, 'temporal.api.common.v1.Payloads'}},
        {{value, failure}, {optional, 'temporal.api.failure.v1.Failure'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.update.v1.Rejection' = N, M, Cl, RI, CC, C) ->
    P = [
        {failure, {optional, 'temporal.api.failure.v1.Failure'}},
        {rejected_request, {optional, 'temporal.api.update.v1.Request'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.update.v1.Request' = N, M, Cl, RI, CC, C) ->
    P = [{input, {optional, 'temporal.api.update.v1.Input'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.update.v1.Response' = N, M, Cl, RI, CC, C) ->
    P = [{outcome, {optional, 'temporal.api.update.v1.Outcome'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflow.v1.CallbackInfo' = N, M, Cl, RI, CC, C) ->
    P = [{last_attempt_failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflow.v1.NewWorkflowExecutionInfo' = N, M, Cl, RI, CC, C) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {memo, {optional, 'temporal.api.common.v1.Memo'}},
        {search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}},
        {header, {optional, 'temporal.api.common.v1.Header'}},
        {user_metadata, {optional, 'temporal.api.sdk.v1.UserMetadata'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflow.v1.NexusOperationCancellationInfo' = N, M, Cl, RI, CC, C) ->
    P = [{last_attempt_failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflow.v1.PendingActivityInfo' = N, M, Cl, RI, CC, C) ->
    P = [
        {heartbeat_details, {optional, 'temporal.api.common.v1.Payloads'}},
        {last_failure, {optional, 'temporal.api.failure.v1.Failure'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflow.v1.PendingNexusOperationInfo' = N, M, Cl, RI, CC, C) ->
    P = [
        {last_attempt_failure, {optional, 'temporal.api.failure.v1.Failure'}},
        {cancellation_info, {optional, 'temporal.api.workflow.v1.NexusOperationCancellationInfo'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflow.v1.PostResetOperation' = N, M, Cl, RI, CC, C) ->
    P = [
        {
            {variant, signal_workflow},
            {optional, 'temporal.api.workflow.v1.PostResetOperation.SignalWorkflow'}
        }
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflow.v1.PostResetOperation.SignalWorkflow' = N, M, Cl, RI, CC, C) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {header, {optional, 'temporal.api.common.v1.Header'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflow.v1.WorkflowExecutionConfig' = N, M, Cl, RI, CC, C) ->
    P = [{user_metadata, {optional, 'temporal.api.sdk.v1.UserMetadata'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflow.v1.WorkflowExecutionInfo' = N, M, Cl, RI, CC, C) ->
    P = [
        {memo, {optional, 'temporal.api.common.v1.Memo'}},
        {search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.CountWorkflowExecutionsResponse' = N, M, Cl, RI, CC, C) ->
    P = [
        {groups,
            {repeated,
                'temporal.api.workflowservice.v1.CountWorkflowExecutionsResponse.AggregationGroup'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.CountWorkflowExecutionsResponse.AggregationGroup' = N,
    M,
    Cl,
    RI,
    CC,
    C
) ->
    P = [{group_values, {repeated, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.CreateScheduleRequest' = N, M, Cl, RI, CC, C) ->
    P = [
        {memo, {optional, 'temporal.api.common.v1.Memo'}},
        {search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}},
        {schedule, {optional, 'temporal.api.schedule.v1.Schedule'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.DescribeDeploymentResponse' = N, M, Cl, RI, CC, C) ->
    P = [{deployment_info, {optional, 'temporal.api.deployment.v1.DeploymentInfo'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.DescribeScheduleResponse' = N, M, Cl, RI, CC, C) ->
    P = [
        {memo, {optional, 'temporal.api.common.v1.Memo'}},
        {search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}},
        {schedule, {optional, 'temporal.api.schedule.v1.Schedule'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.DescribeWorkerDeploymentVersionResponse' = N, M, Cl, RI, CC, C
) ->
    P = [
        {worker_deployment_version_info,
            {optional, 'temporal.api.deployment.v1.WorkerDeploymentVersionInfo'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.DescribeWorkflowExecutionResponse' = N, M, Cl, RI, CC, C) ->
    P = [
        {pending_activities, {repeated, 'temporal.api.workflow.v1.PendingActivityInfo'}},
        {workflow_execution_info, {optional, 'temporal.api.workflow.v1.WorkflowExecutionInfo'}},
        {callbacks, {repeated, 'temporal.api.workflow.v1.CallbackInfo'}},
        {pending_nexus_operations,
            {repeated, 'temporal.api.workflow.v1.PendingNexusOperationInfo'}},
        {execution_config, {optional, 'temporal.api.workflow.v1.WorkflowExecutionConfig'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.ExecuteMultiOperationRequest' = N, M, Cl, RI, CC, C) ->
    P = [
        {operations,
            {repeated, 'temporal.api.workflowservice.v1.ExecuteMultiOperationRequest.Operation'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.ExecuteMultiOperationRequest.Operation' = N, M, Cl, RI, CC, C
) ->
    P = [
        {
            {operation, start_workflow},
            {optional, 'temporal.api.workflowservice.v1.StartWorkflowExecutionRequest'}
        },
        {
            {operation, update_workflow},
            {optional, 'temporal.api.workflowservice.v1.UpdateWorkflowExecutionRequest'}
        }
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.ExecuteMultiOperationResponse' = N, M, Cl, RI, CC, C) ->
    P = [
        {responses,
            {repeated, 'temporal.api.workflowservice.v1.ExecuteMultiOperationResponse.Response'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.ExecuteMultiOperationResponse.Response' = N, M, Cl, RI, CC, C
) ->
    P = [
        {
            {response, update_workflow},
            {optional, 'temporal.api.workflowservice.v1.UpdateWorkflowExecutionResponse'}
        },
        {
            {response, start_workflow},
            {optional, 'temporal.api.workflowservice.v1.StartWorkflowExecutionResponse'}
        }
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.GetCurrentDeploymentResponse' = N, M, Cl, RI, CC, C) ->
    P = [{current_deployment_info, {optional, 'temporal.api.deployment.v1.DeploymentInfo'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.GetDeploymentReachabilityResponse' = N, M, Cl, RI, CC, C) ->
    P = [{deployment_info, {optional, 'temporal.api.deployment.v1.DeploymentInfo'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryResponse' = N, M, Cl, RI, CC, C
) ->
    P = [{history, {optional, 'temporal.api.history.v1.History'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryReverseResponse' = N,
    M,
    Cl,
    RI,
    CC,
    C
) ->
    P = [{history, {optional, 'temporal.api.history.v1.History'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.ListArchivedWorkflowExecutionsResponse' = N, M, Cl, RI, CC, C
) ->
    P = [{executions, {repeated, 'temporal.api.workflow.v1.WorkflowExecutionInfo'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.ListClosedWorkflowExecutionsResponse' = N, M, Cl, RI, CC, C
) ->
    P = [{executions, {repeated, 'temporal.api.workflow.v1.WorkflowExecutionInfo'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.ListOpenWorkflowExecutionsResponse' = N, M, Cl, RI, CC, C) ->
    P = [{executions, {repeated, 'temporal.api.workflow.v1.WorkflowExecutionInfo'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.ListSchedulesResponse' = N, M, Cl, RI, CC, C) ->
    P = [{schedules, {repeated, 'temporal.api.schedule.v1.ScheduleListEntry'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.ListWorkflowExecutionsResponse' = N, M, Cl, RI, CC, C) ->
    P = [{executions, {repeated, 'temporal.api.workflow.v1.WorkflowExecutionInfo'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.PollActivityTaskQueueResponse' = N, M, Cl, RI, CC, C) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {heartbeat_details, {optional, 'temporal.api.common.v1.Payloads'}},
        {header, {optional, 'temporal.api.common.v1.Header'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.PollNexusTaskQueueResponse' = N, M, Cl, RI, CC, C) ->
    P = [{request, {optional, 'temporal.api.nexus.v1.Request'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.PollWorkflowExecutionUpdateResponse' = N, M, Cl, RI, CC, C
) ->
    P = [{outcome, {optional, 'temporal.api.update.v1.Outcome'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.PollWorkflowTaskQueueResponse' = N, M, Cl, RI, CC, C) ->
    P = [
        {query, {optional, 'temporal.api.query.v1.WorkflowQuery'}},
        {queries, {map_string, 'temporal.api.query.v1.WorkflowQuery'}},
        {history, {optional, 'temporal.api.history.v1.History'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.QueryWorkflowRequest' = N, M, Cl, RI, CC, C) ->
    P = [{query, {optional, 'temporal.api.query.v1.WorkflowQuery'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.QueryWorkflowResponse' = N, M, Cl, RI, CC, C) ->
    P = [{query_result, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.RecordActivityTaskHeartbeatByIdRequest' = N, M, Cl, RI, CC, C
) ->
    P = [{details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.RecordActivityTaskHeartbeatRequest' = N, M, Cl, RI, CC, C) ->
    P = [{details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.ResetWorkflowExecutionRequest' = N, M, Cl, RI, CC, C) ->
    P = [{post_reset_operations, {repeated, 'temporal.api.workflow.v1.PostResetOperation'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.RespondActivityTaskCanceledByIdRequest' = N, M, Cl, RI, CC, C
) ->
    P = [{details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.RespondActivityTaskCanceledRequest' = N, M, Cl, RI, CC, C) ->
    P = [{details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.RespondActivityTaskCompletedByIdRequest' = N, M, Cl, RI, CC, C
) ->
    P = [{result, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.RespondActivityTaskCompletedRequest' = N, M, Cl, RI, CC, C
) ->
    P = [{result, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.RespondActivityTaskFailedByIdRequest' = N, M, Cl, RI, CC, C
) ->
    P = [
        {last_heartbeat_details, {optional, 'temporal.api.common.v1.Payloads'}},
        {failure, {optional, 'temporal.api.failure.v1.Failure'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.RespondActivityTaskFailedByIdResponse' = N, M, Cl, RI, CC, C
) ->
    P = [{failures, {repeated, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.RespondActivityTaskFailedRequest' = N, M, Cl, RI, CC, C) ->
    P = [
        {last_heartbeat_details, {optional, 'temporal.api.common.v1.Payloads'}},
        {failure, {optional, 'temporal.api.failure.v1.Failure'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.RespondActivityTaskFailedResponse' = N, M, Cl, RI, CC, C) ->
    P = [{failures, {repeated, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.RespondNexusTaskCompletedRequest' = N, M, Cl, RI, CC, C) ->
    P = [{response, {optional, 'temporal.api.nexus.v1.Response'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.RespondQueryTaskCompletedRequest' = N, M, Cl, RI, CC, C) ->
    P = [
        {query_result, {optional, 'temporal.api.common.v1.Payloads'}},
        {failure, {optional, 'temporal.api.failure.v1.Failure'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.RespondWorkflowTaskCompletedRequest' = N, M, Cl, RI, CC, C
) ->
    P = [
        {query_results, {map_string, 'temporal.api.query.v1.WorkflowQueryResult'}},
        {commands, {repeated, 'temporal.api.command.v1.Command'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.RespondWorkflowTaskCompletedResponse' = N, M, Cl, RI, CC, C
) ->
    P = [
        {activity_tasks,
            {repeated, 'temporal.api.workflowservice.v1.PollActivityTaskQueueResponse'}},
        {workflow_task, {optional, 'temporal.api.workflowservice.v1.PollWorkflowTaskQueueResponse'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.RespondWorkflowTaskFailedRequest' = N, M, Cl, RI, CC, C) ->
    P = [{failure, {optional, 'temporal.api.failure.v1.Failure'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.ScanWorkflowExecutionsResponse' = N, M, Cl, RI, CC, C) ->
    P = [{executions, {repeated, 'temporal.api.workflow.v1.WorkflowExecutionInfo'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.SetCurrentDeploymentRequest' = N, M, Cl, RI, CC, C) ->
    P = [{update_metadata, {optional, 'temporal.api.deployment.v1.UpdateDeploymentMetadata'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.SetCurrentDeploymentResponse' = N, M, Cl, RI, CC, C) ->
    P = [
        {current_deployment_info, {optional, 'temporal.api.deployment.v1.DeploymentInfo'}},
        {previous_deployment_info, {optional, 'temporal.api.deployment.v1.DeploymentInfo'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.SignalWithStartWorkflowExecutionRequest' = N, M, Cl, RI, CC, C
) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {signal_input, {optional, 'temporal.api.common.v1.Payloads'}},
        {memo, {optional, 'temporal.api.common.v1.Memo'}},
        {search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}},
        {header, {optional, 'temporal.api.common.v1.Header'}},
        {user_metadata, {optional, 'temporal.api.sdk.v1.UserMetadata'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.SignalWorkflowExecutionRequest' = N, M, Cl, RI, CC, C) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {header, {optional, 'temporal.api.common.v1.Header'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.StartBatchOperationRequest' = N, M, Cl, RI, CC, C) ->
    P = [
        {{operation, signal_operation}, {optional, 'temporal.api.batch.v1.BatchOperationSignal'}},
        {
            {operation, termination_operation},
            {optional, 'temporal.api.batch.v1.BatchOperationTermination'}
        },
        {{operation, reset_operation}, {optional, 'temporal.api.batch.v1.BatchOperationReset'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.StartWorkflowExecutionRequest' = N, M, Cl, RI, CC, C) ->
    P = [
        {input, {optional, 'temporal.api.common.v1.Payloads'}},
        {last_completion_result, {optional, 'temporal.api.common.v1.Payloads'}},
        {memo, {optional, 'temporal.api.common.v1.Memo'}},
        {search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}},
        {header, {optional, 'temporal.api.common.v1.Header'}},
        {continued_failure, {optional, 'temporal.api.failure.v1.Failure'}},
        {user_metadata, {optional, 'temporal.api.sdk.v1.UserMetadata'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.StartWorkflowExecutionResponse' = N, M, Cl, RI, CC, C) ->
    P = [
        {eager_workflow_task,
            {optional, 'temporal.api.workflowservice.v1.PollWorkflowTaskQueueResponse'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.TerminateWorkflowExecutionRequest' = N, M, Cl, RI, CC, C) ->
    P = [{details, {optional, 'temporal.api.common.v1.Payloads'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.UpdateScheduleRequest' = N, M, Cl, RI, CC, C) ->
    P = [
        {search_attributes, {optional, 'temporal.api.common.v1.SearchAttributes'}},
        {schedule, {optional, 'temporal.api.schedule.v1.Schedule'}}
    ],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.UpdateWorkerDeploymentVersionMetadataRequest' = N,
    M,
    Cl,
    RI,
    CC,
    C
) ->
    P = [{upsert_entries, {map_string, 'temporal.api.common.v1.Payload'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert(
    'temporal.api.workflowservice.v1.UpdateWorkerDeploymentVersionMetadataResponse' = N,
    M,
    Cl,
    RI,
    CC,
    C
) ->
    P = [{metadata, {optional, 'temporal.api.deployment.v1.VersionMetadata'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.UpdateWorkflowExecutionRequest' = N, M, Cl, RI, CC, C) ->
    P = [{request, {optional, 'temporal.api.update.v1.Request'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.workflowservice.v1.UpdateWorkflowExecutionResponse' = N, M, Cl, RI, CC, C) ->
    P = [{outcome, {optional, 'temporal.api.update.v1.Outcome'}}],
    convert_paths(P, N, M, Cl, RI, CC, C);
convert('temporal.api.common.v1.Payload', M, Cl, RI, _CC, C) ->
    convert_payload(M, Cl, RI, C);
convert(_, M, _, _, _, _) ->
    {ok, M}.
