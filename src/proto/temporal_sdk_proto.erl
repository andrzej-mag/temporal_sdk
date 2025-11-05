%% Automatically generated, do not edit.
%% gpb library version:          4.21.5
%% temporal_sdk_proto version:   0.1.0
%% Temporal API version tag:     v1.56.0-1-g831691d

-module(temporal_sdk_proto).

% elp:ignore W0012 W0040
-moduledoc """
Temporal gRPC services module.
""".

-export([info/1]).

-type service_info() :: #{
    content_type := binary(),
    input :=
        temporal_sdk_proto_service_workflow_strings:'$msg_name'()
        | temporal_sdk_proto_service_operator_strings:'$msg_name'(),
    input_stream := boolean(),
    output :=
        temporal_sdk_proto_service_workflow_strings:'$msg_name'()
        | temporal_sdk_proto_service_operator_strings:'$msg_name'(),
    output_stream := boolean(),
    msg_type := binary(),
    name := atom(),
    opts := list(),
    service_fqname :=
        'temporal.api.workflowservice.v1.WorkflowService'
        | 'temporal.api.operatorservice.v1.OperatorService'
}.

-export_type([service_info/0]).

-type service() ::
    'RegisterNamespace'
    | 'DescribeNamespace'
    | 'ListNamespaces'
    | 'UpdateNamespace'
    | 'DeprecateNamespace'
    | 'StartWorkflowExecution'
    | 'ExecuteMultiOperation'
    | 'GetWorkflowExecutionHistory'
    | 'GetWorkflowExecutionHistoryReverse'
    | 'PollWorkflowTaskQueue'
    | 'RespondWorkflowTaskCompleted'
    | 'RespondWorkflowTaskFailed'
    | 'PollActivityTaskQueue'
    | 'RecordActivityTaskHeartbeat'
    | 'RecordActivityTaskHeartbeatById'
    | 'RespondActivityTaskCompleted'
    | 'RespondActivityTaskCompletedById'
    | 'RespondActivityTaskFailed'
    | 'RespondActivityTaskFailedById'
    | 'RespondActivityTaskCanceled'
    | 'RespondActivityTaskCanceledById'
    | 'RequestCancelWorkflowExecution'
    | 'SignalWorkflowExecution'
    | 'SignalWithStartWorkflowExecution'
    | 'ResetWorkflowExecution'
    | 'TerminateWorkflowExecution'
    | 'DeleteWorkflowExecution'
    | 'ListOpenWorkflowExecutions'
    | 'ListClosedWorkflowExecutions'
    | 'ListWorkflowExecutions'
    | 'ListArchivedWorkflowExecutions'
    | 'ScanWorkflowExecutions'
    | 'CountWorkflowExecutions'
    | 'GetSearchAttributes'
    | 'RespondQueryTaskCompleted'
    | 'ResetStickyTaskQueue'
    | 'ShutdownWorker'
    | 'QueryWorkflow'
    | 'DescribeWorkflowExecution'
    | 'DescribeTaskQueue'
    | 'GetClusterInfo'
    | 'GetSystemInfo'
    | 'ListTaskQueuePartitions'
    | 'CreateSchedule'
    | 'DescribeSchedule'
    | 'UpdateSchedule'
    | 'PatchSchedule'
    | 'ListScheduleMatchingTimes'
    | 'DeleteSchedule'
    | 'ListSchedules'
    | 'UpdateWorkerBuildIdCompatibility'
    | 'GetWorkerBuildIdCompatibility'
    | 'UpdateWorkerVersioningRules'
    | 'GetWorkerVersioningRules'
    | 'GetWorkerTaskReachability'
    | 'DescribeDeployment'
    | 'DescribeWorkerDeploymentVersion'
    | 'ListDeployments'
    | 'GetDeploymentReachability'
    | 'GetCurrentDeployment'
    | 'SetCurrentDeployment'
    | 'SetWorkerDeploymentCurrentVersion'
    | 'DescribeWorkerDeployment'
    | 'DeleteWorkerDeployment'
    | 'DeleteWorkerDeploymentVersion'
    | 'SetWorkerDeploymentRampingVersion'
    | 'ListWorkerDeployments'
    | 'UpdateWorkerDeploymentVersionMetadata'
    | 'SetWorkerDeploymentManager'
    | 'UpdateWorkflowExecution'
    | 'PollWorkflowExecutionUpdate'
    | 'StartBatchOperation'
    | 'StopBatchOperation'
    | 'DescribeBatchOperation'
    | 'ListBatchOperations'
    | 'PollNexusTaskQueue'
    | 'RespondNexusTaskCompleted'
    | 'RespondNexusTaskFailed'
    | 'UpdateActivityOptions'
    | 'UpdateWorkflowExecutionOptions'
    | 'PauseActivity'
    | 'UnpauseActivity'
    | 'ResetActivity'
    | 'CreateWorkflowRule'
    | 'DescribeWorkflowRule'
    | 'DeleteWorkflowRule'
    | 'ListWorkflowRules'
    | 'TriggerWorkflowRule'
    | 'RecordWorkerHeartbeat'
    | 'ListWorkers'
    | 'UpdateTaskQueueConfig'
    | 'FetchWorkerConfig'
    | 'UpdateWorkerConfig'
    | 'DescribeWorker'
    | 'AddSearchAttributes'
    | 'RemoveSearchAttributes'
    | 'ListSearchAttributes'
    | 'DeleteNamespace'
    | 'AddOrUpdateRemoteCluster'
    | 'RemoveRemoteCluster'
    | 'ListClusters'
    | 'GetNexusEndpoint'
    | 'CreateNexusEndpoint'
    | 'UpdateNexusEndpoint'
    | 'DeleteNexusEndpoint'
    | 'ListNexusEndpoints'.

-export_type([service/0]).

-spec info(Service :: service()) -> service_info().

info('RegisterNamespace') ->
    #{
        input => 'temporal.api.workflowservice.v1.RegisterNamespaceRequest',
        name => 'RegisterNamespace',
        output => 'temporal.api.workflowservice.v1.RegisterNamespaceResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/cluster/namespaces\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 103, 105,
                115, 116, 101, 114, 78, 97, 109, 101, 115, 112, 97, 99, 101, 82, 101, 113, 117, 101,
                115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DescribeNamespace') ->
    #{
        input => 'temporal.api.workflowservice.v1.DescribeNamespaceRequest',
        name => 'DescribeNamespace',
        output => 'temporal.api.workflowservice.v1.DescribeNamespaceResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/cluster/namespaces/{namespace}\" additional_bindings { get : \"/api/v1/namespaces/{namespace}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 115, 99,
                114, 105, 98, 101, 78, 97, 109, 101, 115, 112, 97, 99, 101, 82, 101, 113, 117, 101,
                115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListNamespaces') ->
    #{
        input => 'temporal.api.workflowservice.v1.ListNamespacesRequest',
        name => 'ListNamespaces',
        output => 'temporal.api.workflowservice.v1.ListNamespacesResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/cluster/namespaces\" additional_bindings { get : \"/api/v1/namespaces\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                78, 97, 109, 101, 115, 112, 97, 99, 101, 115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('UpdateNamespace') ->
    #{
        input => 'temporal.api.workflowservice.v1.UpdateNamespaceRequest',
        name => 'UpdateNamespace',
        output => 'temporal.api.workflowservice.v1.UpdateNamespaceResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/cluster/namespaces/{namespace}/update\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/update\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 85, 112, 100, 97,
                116, 101, 78, 97, 109, 101, 115, 112, 97, 99, 101, 82, 101, 113, 117, 101, 115,
                116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DeprecateNamespace') ->
    #{
        input => 'temporal.api.workflowservice.v1.DeprecateNamespaceRequest',
        name => 'DeprecateNamespace',
        output => 'temporal.api.workflowservice.v1.DeprecateNamespaceResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 112, 114,
                101, 99, 97, 116, 101, 78, 97, 109, 101, 115, 112, 97, 99, 101, 82, 101, 113, 117,
                101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('StartWorkflowExecution') ->
    #{
        input => 'temporal.api.workflowservice.v1.StartWorkflowExecutionRequest',
        name => 'StartWorkflowExecution',
        output => 'temporal.api.workflowservice.v1.StartWorkflowExecutionResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workflows/{workflow_id}\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workflows/{workflow_id}\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 83, 116, 97, 114,
                116, 87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117, 116, 105, 111,
                110, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ExecuteMultiOperation') ->
    #{
        input => 'temporal.api.workflowservice.v1.ExecuteMultiOperationRequest',
        name => 'ExecuteMultiOperation',
        output => 'temporal.api.workflowservice.v1.ExecuteMultiOperationResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workflows/execute-multi-operation\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workflows/execute-multi-operation\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 69, 120, 101, 99,
                117, 116, 101, 77, 117, 108, 116, 105, 79, 112, 101, 114, 97, 116, 105, 111, 110,
                82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('GetWorkflowExecutionHistory') ->
    #{
        input => 'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryRequest',
        name => 'GetWorkflowExecutionHistory',
        output => 'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/workflows/{execution.workflow_id}/history\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/workflows/{execution.workflow_id}/history\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 71, 101, 116, 87,
                111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117, 116, 105, 111, 110, 72,
                105, 115, 116, 111, 114, 121, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('GetWorkflowExecutionHistoryReverse') ->
    #{
        input => 'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryReverseRequest',
        name => 'GetWorkflowExecutionHistoryReverse',
        output => 'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryReverseResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/workflows/{execution.workflow_id}/history-reverse\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/workflows/{execution.workflow_id}/history-reverse\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 71, 101, 116, 87,
                111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117, 116, 105, 111, 110, 72,
                105, 115, 116, 111, 114, 121, 82, 101, 118, 101, 114, 115, 101, 82, 101, 113, 117,
                101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('PollWorkflowTaskQueue') ->
    #{
        input => 'temporal.api.workflowservice.v1.PollWorkflowTaskQueueRequest',
        name => 'PollWorkflowTaskQueue',
        output => 'temporal.api.workflowservice.v1.PollWorkflowTaskQueueResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 80, 111, 108, 108,
                87, 111, 114, 107, 102, 108, 111, 119, 84, 97, 115, 107, 81, 117, 101, 117, 101, 82,
                101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RespondWorkflowTaskCompleted') ->
    #{
        input => 'temporal.api.workflowservice.v1.RespondWorkflowTaskCompletedRequest',
        name => 'RespondWorkflowTaskCompleted',
        output => 'temporal.api.workflowservice.v1.RespondWorkflowTaskCompletedResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 112,
                111, 110, 100, 87, 111, 114, 107, 102, 108, 111, 119, 84, 97, 115, 107, 67, 111,
                109, 112, 108, 101, 116, 101, 100, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RespondWorkflowTaskFailed') ->
    #{
        input => 'temporal.api.workflowservice.v1.RespondWorkflowTaskFailedRequest',
        name => 'RespondWorkflowTaskFailed',
        output => 'temporal.api.workflowservice.v1.RespondWorkflowTaskFailedResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 112,
                111, 110, 100, 87, 111, 114, 107, 102, 108, 111, 119, 84, 97, 115, 107, 70, 97, 105,
                108, 101, 100, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('PollActivityTaskQueue') ->
    #{
        input => 'temporal.api.workflowservice.v1.PollActivityTaskQueueRequest',
        name => 'PollActivityTaskQueue',
        output => 'temporal.api.workflowservice.v1.PollActivityTaskQueueResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 80, 111, 108, 108,
                65, 99, 116, 105, 118, 105, 116, 121, 84, 97, 115, 107, 81, 117, 101, 117, 101, 82,
                101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RecordActivityTaskHeartbeat') ->
    #{
        input => 'temporal.api.workflowservice.v1.RecordActivityTaskHeartbeatRequest',
        name => 'RecordActivityTaskHeartbeat',
        output => 'temporal.api.workflowservice.v1.RecordActivityTaskHeartbeatResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/activities/heartbeat\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/activities/heartbeat\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 99, 111,
                114, 100, 65, 99, 116, 105, 118, 105, 116, 121, 84, 97, 115, 107, 72, 101, 97, 114,
                116, 98, 101, 97, 116, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RecordActivityTaskHeartbeatById') ->
    #{
        input => 'temporal.api.workflowservice.v1.RecordActivityTaskHeartbeatByIdRequest',
        name => 'RecordActivityTaskHeartbeatById',
        output => 'temporal.api.workflowservice.v1.RecordActivityTaskHeartbeatByIdResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/activities/heartbeat-by-id\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/activities/heartbeat-by-id\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 99, 111,
                114, 100, 65, 99, 116, 105, 118, 105, 116, 121, 84, 97, 115, 107, 72, 101, 97, 114,
                116, 98, 101, 97, 116, 66, 121, 73, 100, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RespondActivityTaskCompleted') ->
    #{
        input => 'temporal.api.workflowservice.v1.RespondActivityTaskCompletedRequest',
        name => 'RespondActivityTaskCompleted',
        output => 'temporal.api.workflowservice.v1.RespondActivityTaskCompletedResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/activities/complete\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/activities/complete\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 112,
                111, 110, 100, 65, 99, 116, 105, 118, 105, 116, 121, 84, 97, 115, 107, 67, 111, 109,
                112, 108, 101, 116, 101, 100, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RespondActivityTaskCompletedById') ->
    #{
        input => 'temporal.api.workflowservice.v1.RespondActivityTaskCompletedByIdRequest',
        name => 'RespondActivityTaskCompletedById',
        output => 'temporal.api.workflowservice.v1.RespondActivityTaskCompletedByIdResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/activities/complete-by-id\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/activities/complete-by-id\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 112,
                111, 110, 100, 65, 99, 116, 105, 118, 105, 116, 121, 84, 97, 115, 107, 67, 111, 109,
                112, 108, 101, 116, 101, 100, 66, 121, 73, 100, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RespondActivityTaskFailed') ->
    #{
        input => 'temporal.api.workflowservice.v1.RespondActivityTaskFailedRequest',
        name => 'RespondActivityTaskFailed',
        output => 'temporal.api.workflowservice.v1.RespondActivityTaskFailedResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/activities/fail\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/activities/fail\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 112,
                111, 110, 100, 65, 99, 116, 105, 118, 105, 116, 121, 84, 97, 115, 107, 70, 97, 105,
                108, 101, 100, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RespondActivityTaskFailedById') ->
    #{
        input => 'temporal.api.workflowservice.v1.RespondActivityTaskFailedByIdRequest',
        name => 'RespondActivityTaskFailedById',
        output => 'temporal.api.workflowservice.v1.RespondActivityTaskFailedByIdResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/activities/fail-by-id\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/activities/fail-by-id\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 112,
                111, 110, 100, 65, 99, 116, 105, 118, 105, 116, 121, 84, 97, 115, 107, 70, 97, 105,
                108, 101, 100, 66, 121, 73, 100, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RespondActivityTaskCanceled') ->
    #{
        input => 'temporal.api.workflowservice.v1.RespondActivityTaskCanceledRequest',
        name => 'RespondActivityTaskCanceled',
        output => 'temporal.api.workflowservice.v1.RespondActivityTaskCanceledResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/activities/cancel\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/activities/cancel\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 112,
                111, 110, 100, 65, 99, 116, 105, 118, 105, 116, 121, 84, 97, 115, 107, 67, 97, 110,
                99, 101, 108, 101, 100, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RespondActivityTaskCanceledById') ->
    #{
        input => 'temporal.api.workflowservice.v1.RespondActivityTaskCanceledByIdRequest',
        name => 'RespondActivityTaskCanceledById',
        output => 'temporal.api.workflowservice.v1.RespondActivityTaskCanceledByIdResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/activities/cancel-by-id\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/activities/cancel-by-id\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 112,
                111, 110, 100, 65, 99, 116, 105, 118, 105, 116, 121, 84, 97, 115, 107, 67, 97, 110,
                99, 101, 108, 101, 100, 66, 121, 73, 100, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RequestCancelWorkflowExecution') ->
    #{
        input => 'temporal.api.workflowservice.v1.RequestCancelWorkflowExecutionRequest',
        name => 'RequestCancelWorkflowExecution',
        output => 'temporal.api.workflowservice.v1.RequestCancelWorkflowExecutionResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/cancel\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/cancel\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 113, 117,
                101, 115, 116, 67, 97, 110, 99, 101, 108, 87, 111, 114, 107, 102, 108, 111, 119, 69,
                120, 101, 99, 117, 116, 105, 111, 110, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('SignalWorkflowExecution') ->
    #{
        input => 'temporal.api.workflowservice.v1.SignalWorkflowExecutionRequest',
        name => 'SignalWorkflowExecution',
        output => 'temporal.api.workflowservice.v1.SignalWorkflowExecutionResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/signal/{signal_name}\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/signal/{signal_name}\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 83, 105, 103, 110,
                97, 108, 87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117, 116, 105,
                111, 110, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('SignalWithStartWorkflowExecution') ->
    #{
        input => 'temporal.api.workflowservice.v1.SignalWithStartWorkflowExecutionRequest',
        name => 'SignalWithStartWorkflowExecution',
        output => 'temporal.api.workflowservice.v1.SignalWithStartWorkflowExecutionResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workflows/{workflow_id}/signal-with-start/{signal_name}\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workflows/{workflow_id}/signal-with-start/{signal_name}\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 83, 105, 103, 110,
                97, 108, 87, 105, 116, 104, 83, 116, 97, 114, 116, 87, 111, 114, 107, 102, 108, 111,
                119, 69, 120, 101, 99, 117, 116, 105, 111, 110, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ResetWorkflowExecution') ->
    #{
        input => 'temporal.api.workflowservice.v1.ResetWorkflowExecutionRequest',
        name => 'ResetWorkflowExecution',
        output => 'temporal.api.workflowservice.v1.ResetWorkflowExecutionResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/reset\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/reset\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 101,
                116, 87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117, 116, 105, 111,
                110, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('TerminateWorkflowExecution') ->
    #{
        input => 'temporal.api.workflowservice.v1.TerminateWorkflowExecutionRequest',
        name => 'TerminateWorkflowExecution',
        output => 'temporal.api.workflowservice.v1.TerminateWorkflowExecutionResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/terminate\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/terminate\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 84, 101, 114, 109,
                105, 110, 97, 116, 101, 87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99,
                117, 116, 105, 111, 110, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DeleteWorkflowExecution') ->
    #{
        input => 'temporal.api.workflowservice.v1.DeleteWorkflowExecutionRequest',
        name => 'DeleteWorkflowExecution',
        output => 'temporal.api.workflowservice.v1.DeleteWorkflowExecutionResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 108, 101,
                116, 101, 87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117, 116, 105,
                111, 110, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListOpenWorkflowExecutions') ->
    #{
        input => 'temporal.api.workflowservice.v1.ListOpenWorkflowExecutionsRequest',
        name => 'ListOpenWorkflowExecutions',
        output => 'temporal.api.workflowservice.v1.ListOpenWorkflowExecutionsResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                79, 112, 101, 110, 87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117,
                116, 105, 111, 110, 115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListClosedWorkflowExecutions') ->
    #{
        input => 'temporal.api.workflowservice.v1.ListClosedWorkflowExecutionsRequest',
        name => 'ListClosedWorkflowExecutions',
        output => 'temporal.api.workflowservice.v1.ListClosedWorkflowExecutionsResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                67, 108, 111, 115, 101, 100, 87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101,
                99, 117, 116, 105, 111, 110, 115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListWorkflowExecutions') ->
    #{
        input => 'temporal.api.workflowservice.v1.ListWorkflowExecutionsRequest',
        name => 'ListWorkflowExecutions',
        output => 'temporal.api.workflowservice.v1.ListWorkflowExecutionsResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/workflows\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/workflows\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117, 116, 105, 111, 110,
                115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListArchivedWorkflowExecutions') ->
    #{
        input => 'temporal.api.workflowservice.v1.ListArchivedWorkflowExecutionsRequest',
        name => 'ListArchivedWorkflowExecutions',
        output => 'temporal.api.workflowservice.v1.ListArchivedWorkflowExecutionsResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/archived-workflows\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/archived-workflows\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                65, 114, 99, 104, 105, 118, 101, 100, 87, 111, 114, 107, 102, 108, 111, 119, 69,
                120, 101, 99, 117, 116, 105, 111, 110, 115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ScanWorkflowExecutions') ->
    #{
        input => 'temporal.api.workflowservice.v1.ScanWorkflowExecutionsRequest',
        name => 'ScanWorkflowExecutions',
        output => 'temporal.api.workflowservice.v1.ScanWorkflowExecutionsResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 83, 99, 97, 110,
                87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117, 116, 105, 111, 110,
                115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('CountWorkflowExecutions') ->
    #{
        input => 'temporal.api.workflowservice.v1.CountWorkflowExecutionsRequest',
        name => 'CountWorkflowExecutions',
        output => 'temporal.api.workflowservice.v1.CountWorkflowExecutionsResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/workflow-count\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/workflow-count\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 67, 111, 117, 110,
                116, 87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117, 116, 105, 111,
                110, 115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('GetSearchAttributes') ->
    #{
        input => 'temporal.api.workflowservice.v1.GetSearchAttributesRequest',
        name => 'GetSearchAttributes',
        output => 'temporal.api.workflowservice.v1.GetSearchAttributesResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 71, 101, 116, 83,
                101, 97, 114, 99, 104, 65, 116, 116, 114, 105, 98, 117, 116, 101, 115, 82, 101, 113,
                117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RespondQueryTaskCompleted') ->
    #{
        input => 'temporal.api.workflowservice.v1.RespondQueryTaskCompletedRequest',
        name => 'RespondQueryTaskCompleted',
        output => 'temporal.api.workflowservice.v1.RespondQueryTaskCompletedResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 112,
                111, 110, 100, 81, 117, 101, 114, 121, 84, 97, 115, 107, 67, 111, 109, 112, 108,
                101, 116, 101, 100, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ResetStickyTaskQueue') ->
    #{
        input => 'temporal.api.workflowservice.v1.ResetStickyTaskQueueRequest',
        name => 'ResetStickyTaskQueue',
        output => 'temporal.api.workflowservice.v1.ResetStickyTaskQueueResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 101,
                116, 83, 116, 105, 99, 107, 121, 84, 97, 115, 107, 81, 117, 101, 117, 101, 82, 101,
                113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ShutdownWorker') ->
    #{
        input => 'temporal.api.workflowservice.v1.ShutdownWorkerRequest',
        name => 'ShutdownWorker',
        output => 'temporal.api.workflowservice.v1.ShutdownWorkerResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 83, 104, 117, 116,
                100, 111, 119, 110, 87, 111, 114, 107, 101, 114, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('QueryWorkflow') ->
    #{
        input => 'temporal.api.workflowservice.v1.QueryWorkflowRequest',
        name => 'QueryWorkflow',
        output => 'temporal.api.workflowservice.v1.QueryWorkflowResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workflows/{execution.workflow_id}/query/{query.query_type}\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workflows/{execution.workflow_id}/query/{query.query_type}\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 81, 117, 101, 114,
                121, 87, 111, 114, 107, 102, 108, 111, 119, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DescribeWorkflowExecution') ->
    #{
        input => 'temporal.api.workflowservice.v1.DescribeWorkflowExecutionRequest',
        name => 'DescribeWorkflowExecution',
        output => 'temporal.api.workflowservice.v1.DescribeWorkflowExecutionResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/workflows/{execution.workflow_id}\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/workflows/{execution.workflow_id}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 115, 99,
                114, 105, 98, 101, 87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117,
                116, 105, 111, 110, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DescribeTaskQueue') ->
    #{
        input => 'temporal.api.workflowservice.v1.DescribeTaskQueueRequest',
        name => 'DescribeTaskQueue',
        output => 'temporal.api.workflowservice.v1.DescribeTaskQueueResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/task-queues/{task_queue.name}\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/task-queues/{task_queue.name}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 115, 99,
                114, 105, 98, 101, 84, 97, 115, 107, 81, 117, 101, 117, 101, 82, 101, 113, 117, 101,
                115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('GetClusterInfo') ->
    #{
        input => 'temporal.api.workflowservice.v1.GetClusterInfoRequest',
        name => 'GetClusterInfo',
        output => 'temporal.api.workflowservice.v1.GetClusterInfoResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/cluster\" additional_bindings { get : \"/api/v1/cluster-info\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 71, 101, 116, 67,
                108, 117, 115, 116, 101, 114, 73, 110, 102, 111, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('GetSystemInfo') ->
    #{
        input => 'temporal.api.workflowservice.v1.GetSystemInfoRequest',
        name => 'GetSystemInfo',
        output => 'temporal.api.workflowservice.v1.GetSystemInfoResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/system-info\" additional_bindings { get : \"/api/v1/system-info\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 71, 101, 116, 83,
                121, 115, 116, 101, 109, 73, 110, 102, 111, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListTaskQueuePartitions') ->
    #{
        input => 'temporal.api.workflowservice.v1.ListTaskQueuePartitionsRequest',
        name => 'ListTaskQueuePartitions',
        output => 'temporal.api.workflowservice.v1.ListTaskQueuePartitionsResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                84, 97, 115, 107, 81, 117, 101, 117, 101, 80, 97, 114, 116, 105, 116, 105, 111, 110,
                115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('CreateSchedule') ->
    #{
        input => 'temporal.api.workflowservice.v1.CreateScheduleRequest',
        name => 'CreateSchedule',
        output => 'temporal.api.workflowservice.v1.CreateScheduleResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/schedules/{schedule_id}\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/schedules/{schedule_id}\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 67, 114, 101, 97,
                116, 101, 83, 99, 104, 101, 100, 117, 108, 101, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DescribeSchedule') ->
    #{
        input => 'temporal.api.workflowservice.v1.DescribeScheduleRequest',
        name => 'DescribeSchedule',
        output => 'temporal.api.workflowservice.v1.DescribeScheduleResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/schedules/{schedule_id}\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/schedules/{schedule_id}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 115, 99,
                114, 105, 98, 101, 83, 99, 104, 101, 100, 117, 108, 101, 82, 101, 113, 117, 101,
                115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('UpdateSchedule') ->
    #{
        input => 'temporal.api.workflowservice.v1.UpdateScheduleRequest',
        name => 'UpdateSchedule',
        output => 'temporal.api.workflowservice.v1.UpdateScheduleResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/schedules/{schedule_id}/update\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/schedules/{schedule_id}/update\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 85, 112, 100, 97,
                116, 101, 83, 99, 104, 101, 100, 117, 108, 101, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('PatchSchedule') ->
    #{
        input => 'temporal.api.workflowservice.v1.PatchScheduleRequest',
        name => 'PatchSchedule',
        output => 'temporal.api.workflowservice.v1.PatchScheduleResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/schedules/{schedule_id}/patch\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/schedules/{schedule_id}/patch\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 80, 97, 116, 99,
                104, 83, 99, 104, 101, 100, 117, 108, 101, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListScheduleMatchingTimes') ->
    #{
        input => 'temporal.api.workflowservice.v1.ListScheduleMatchingTimesRequest',
        name => 'ListScheduleMatchingTimes',
        output => 'temporal.api.workflowservice.v1.ListScheduleMatchingTimesResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/schedules/{schedule_id}/matching-times\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/schedules/{schedule_id}/matching-times\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                83, 99, 104, 101, 100, 117, 108, 101, 77, 97, 116, 99, 104, 105, 110, 103, 84, 105,
                109, 101, 115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DeleteSchedule') ->
    #{
        input => 'temporal.api.workflowservice.v1.DeleteScheduleRequest',
        name => 'DeleteSchedule',
        output => 'temporal.api.workflowservice.v1.DeleteScheduleResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ delete : \"/namespaces/{namespace}/schedules/{schedule_id}\" additional_bindings { delete : \"/api/v1/namespaces/{namespace}/schedules/{schedule_id}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 108, 101,
                116, 101, 83, 99, 104, 101, 100, 117, 108, 101, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListSchedules') ->
    #{
        input => 'temporal.api.workflowservice.v1.ListSchedulesRequest',
        name => 'ListSchedules',
        output => 'temporal.api.workflowservice.v1.ListSchedulesResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/schedules\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/schedules\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                83, 99, 104, 101, 100, 117, 108, 101, 115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('UpdateWorkerBuildIdCompatibility') ->
    #{
        input => 'temporal.api.workflowservice.v1.UpdateWorkerBuildIdCompatibilityRequest',
        name => 'UpdateWorkerBuildIdCompatibility',
        output => 'temporal.api.workflowservice.v1.UpdateWorkerBuildIdCompatibilityResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 85, 112, 100, 97,
                116, 101, 87, 111, 114, 107, 101, 114, 66, 117, 105, 108, 100, 73, 100, 67, 111,
                109, 112, 97, 116, 105, 98, 105, 108, 105, 116, 121, 82, 101, 113, 117, 101, 115,
                116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('GetWorkerBuildIdCompatibility') ->
    #{
        input => 'temporal.api.workflowservice.v1.GetWorkerBuildIdCompatibilityRequest',
        name => 'GetWorkerBuildIdCompatibility',
        output => 'temporal.api.workflowservice.v1.GetWorkerBuildIdCompatibilityResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/task-queues/{task_queue}/worker-build-id-compatibility\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/task-queues/{task_queue}/worker-build-id-compatibility\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 71, 101, 116, 87,
                111, 114, 107, 101, 114, 66, 117, 105, 108, 100, 73, 100, 67, 111, 109, 112, 97,
                116, 105, 98, 105, 108, 105, 116, 121, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('UpdateWorkerVersioningRules') ->
    #{
        input => 'temporal.api.workflowservice.v1.UpdateWorkerVersioningRulesRequest',
        name => 'UpdateWorkerVersioningRules',
        output => 'temporal.api.workflowservice.v1.UpdateWorkerVersioningRulesResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 85, 112, 100, 97,
                116, 101, 87, 111, 114, 107, 101, 114, 86, 101, 114, 115, 105, 111, 110, 105, 110,
                103, 82, 117, 108, 101, 115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('GetWorkerVersioningRules') ->
    #{
        input => 'temporal.api.workflowservice.v1.GetWorkerVersioningRulesRequest',
        name => 'GetWorkerVersioningRules',
        output => 'temporal.api.workflowservice.v1.GetWorkerVersioningRulesResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/task-queues/{task_queue}/worker-versioning-rules\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/task-queues/{task_queue}/worker-versioning-rules\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 71, 101, 116, 87,
                111, 114, 107, 101, 114, 86, 101, 114, 115, 105, 111, 110, 105, 110, 103, 82, 117,
                108, 101, 115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('GetWorkerTaskReachability') ->
    #{
        input => 'temporal.api.workflowservice.v1.GetWorkerTaskReachabilityRequest',
        name => 'GetWorkerTaskReachability',
        output => 'temporal.api.workflowservice.v1.GetWorkerTaskReachabilityResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/worker-task-reachability\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/worker-task-reachability\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 71, 101, 116, 87,
                111, 114, 107, 101, 114, 84, 97, 115, 107, 82, 101, 97, 99, 104, 97, 98, 105, 108,
                105, 116, 121, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DescribeDeployment') ->
    #{
        input => 'temporal.api.workflowservice.v1.DescribeDeploymentRequest',
        name => 'DescribeDeployment',
        output => 'temporal.api.workflowservice.v1.DescribeDeploymentResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/deployments/{deployment.series_name}/{deployment.build_id}\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/deployments/{deployment.series_name}/{deployment.build_id}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 115, 99,
                114, 105, 98, 101, 68, 101, 112, 108, 111, 121, 109, 101, 110, 116, 82, 101, 113,
                117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DescribeWorkerDeploymentVersion') ->
    #{
        input => 'temporal.api.workflowservice.v1.DescribeWorkerDeploymentVersionRequest',
        name => 'DescribeWorkerDeploymentVersion',
        output => 'temporal.api.workflowservice.v1.DescribeWorkerDeploymentVersionResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 115, 99,
                114, 105, 98, 101, 87, 111, 114, 107, 101, 114, 68, 101, 112, 108, 111, 121, 109,
                101, 110, 116, 86, 101, 114, 115, 105, 111, 110, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListDeployments') ->
    #{
        input => 'temporal.api.workflowservice.v1.ListDeploymentsRequest',
        name => 'ListDeployments',
        output => 'temporal.api.workflowservice.v1.ListDeploymentsResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/deployments\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/deployments\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                68, 101, 112, 108, 111, 121, 109, 101, 110, 116, 115, 82, 101, 113, 117, 101, 115,
                116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('GetDeploymentReachability') ->
    #{
        input => 'temporal.api.workflowservice.v1.GetDeploymentReachabilityRequest',
        name => 'GetDeploymentReachability',
        output => 'temporal.api.workflowservice.v1.GetDeploymentReachabilityResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/deployments/{deployment.series_name}/{deployment.build_id}/reachability\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/deployments/{deployment.series_name}/{deployment.build_id}/reachability\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 71, 101, 116, 68,
                101, 112, 108, 111, 121, 109, 101, 110, 116, 82, 101, 97, 99, 104, 97, 98, 105, 108,
                105, 116, 121, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('GetCurrentDeployment') ->
    #{
        input => 'temporal.api.workflowservice.v1.GetCurrentDeploymentRequest',
        name => 'GetCurrentDeployment',
        output => 'temporal.api.workflowservice.v1.GetCurrentDeploymentResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/current-deployment/{series_name}\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/current-deployment/{series_name}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 71, 101, 116, 67,
                117, 114, 114, 101, 110, 116, 68, 101, 112, 108, 111, 121, 109, 101, 110, 116, 82,
                101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('SetCurrentDeployment') ->
    #{
        input => 'temporal.api.workflowservice.v1.SetCurrentDeploymentRequest',
        name => 'SetCurrentDeployment',
        output => 'temporal.api.workflowservice.v1.SetCurrentDeploymentResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/current-deployment/{deployment.series_name}\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/current-deployment/{deployment.series_name}\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 83, 101, 116, 67,
                117, 114, 114, 101, 110, 116, 68, 101, 112, 108, 111, 121, 109, 101, 110, 116, 82,
                101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('SetWorkerDeploymentCurrentVersion') ->
    #{
        input => 'temporal.api.workflowservice.v1.SetWorkerDeploymentCurrentVersionRequest',
        name => 'SetWorkerDeploymentCurrentVersion',
        output => 'temporal.api.workflowservice.v1.SetWorkerDeploymentCurrentVersionResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/worker-deployments/{deployment_name}/set-current-version\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/worker-deployments/{deployment_name}/set-current-version\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 83, 101, 116, 87,
                111, 114, 107, 101, 114, 68, 101, 112, 108, 111, 121, 109, 101, 110, 116, 67, 117,
                114, 114, 101, 110, 116, 86, 101, 114, 115, 105, 111, 110, 82, 101, 113, 117, 101,
                115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DescribeWorkerDeployment') ->
    #{
        input => 'temporal.api.workflowservice.v1.DescribeWorkerDeploymentRequest',
        name => 'DescribeWorkerDeployment',
        output => 'temporal.api.workflowservice.v1.DescribeWorkerDeploymentResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/worker-deployments/{deployment_name}\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/worker-deployments/{deployment_name}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 115, 99,
                114, 105, 98, 101, 87, 111, 114, 107, 101, 114, 68, 101, 112, 108, 111, 121, 109,
                101, 110, 116, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DeleteWorkerDeployment') ->
    #{
        input => 'temporal.api.workflowservice.v1.DeleteWorkerDeploymentRequest',
        name => 'DeleteWorkerDeployment',
        output => 'temporal.api.workflowservice.v1.DeleteWorkerDeploymentResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ delete : \"/namespaces/{namespace}/worker-deployments/{deployment_name}\" additional_bindings { delete : \"/api/v1/namespaces/{namespace}/worker-deployments/{deployment_name}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 108, 101,
                116, 101, 87, 111, 114, 107, 101, 114, 68, 101, 112, 108, 111, 121, 109, 101, 110,
                116, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DeleteWorkerDeploymentVersion') ->
    #{
        input => 'temporal.api.workflowservice.v1.DeleteWorkerDeploymentVersionRequest',
        name => 'DeleteWorkerDeploymentVersion',
        output => 'temporal.api.workflowservice.v1.DeleteWorkerDeploymentVersionResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ delete : \"/namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}\" additional_bindings { delete : \"/api/v1/namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 108, 101,
                116, 101, 87, 111, 114, 107, 101, 114, 68, 101, 112, 108, 111, 121, 109, 101, 110,
                116, 86, 101, 114, 115, 105, 111, 110, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('SetWorkerDeploymentRampingVersion') ->
    #{
        input => 'temporal.api.workflowservice.v1.SetWorkerDeploymentRampingVersionRequest',
        name => 'SetWorkerDeploymentRampingVersion',
        output => 'temporal.api.workflowservice.v1.SetWorkerDeploymentRampingVersionResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/worker-deployments/{deployment_name}/set-ramping-version\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/worker-deployments/{deployment_name}/set-ramping-version\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 83, 101, 116, 87,
                111, 114, 107, 101, 114, 68, 101, 112, 108, 111, 121, 109, 101, 110, 116, 82, 97,
                109, 112, 105, 110, 103, 86, 101, 114, 115, 105, 111, 110, 82, 101, 113, 117, 101,
                115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListWorkerDeployments') ->
    #{
        input => 'temporal.api.workflowservice.v1.ListWorkerDeploymentsRequest',
        name => 'ListWorkerDeployments',
        output => 'temporal.api.workflowservice.v1.ListWorkerDeploymentsResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/worker-deployments\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/worker-deployments\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                87, 111, 114, 107, 101, 114, 68, 101, 112, 108, 111, 121, 109, 101, 110, 116, 115,
                82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('UpdateWorkerDeploymentVersionMetadata') ->
    #{
        input => 'temporal.api.workflowservice.v1.UpdateWorkerDeploymentVersionMetadataRequest',
        name => 'UpdateWorkerDeploymentVersionMetadata',
        output => 'temporal.api.workflowservice.v1.UpdateWorkerDeploymentVersionMetadataResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}/update-metadata\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}/update-metadata\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 85, 112, 100, 97,
                116, 101, 87, 111, 114, 107, 101, 114, 68, 101, 112, 108, 111, 121, 109, 101, 110,
                116, 86, 101, 114, 115, 105, 111, 110, 77, 101, 116, 97, 100, 97, 116, 97, 82, 101,
                113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('SetWorkerDeploymentManager') ->
    #{
        input => 'temporal.api.workflowservice.v1.SetWorkerDeploymentManagerRequest',
        name => 'SetWorkerDeploymentManager',
        output => 'temporal.api.workflowservice.v1.SetWorkerDeploymentManagerResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/worker-deployments/{deployment_name}/set-manager\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/worker-deployments/{deployment_name}/set-manager\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 83, 101, 116, 87,
                111, 114, 107, 101, 114, 68, 101, 112, 108, 111, 121, 109, 101, 110, 116, 77, 97,
                110, 97, 103, 101, 114, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('UpdateWorkflowExecution') ->
    #{
        input => 'temporal.api.workflowservice.v1.UpdateWorkflowExecutionRequest',
        name => 'UpdateWorkflowExecution',
        output => 'temporal.api.workflowservice.v1.UpdateWorkflowExecutionResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/update/{request.input.name}\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/update/{request.input.name}\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 85, 112, 100, 97,
                116, 101, 87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117, 116, 105,
                111, 110, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('PollWorkflowExecutionUpdate') ->
    #{
        input => 'temporal.api.workflowservice.v1.PollWorkflowExecutionUpdateRequest',
        name => 'PollWorkflowExecutionUpdate',
        output => 'temporal.api.workflowservice.v1.PollWorkflowExecutionUpdateResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 80, 111, 108, 108,
                87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117, 116, 105, 111, 110,
                85, 112, 100, 97, 116, 101, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('StartBatchOperation') ->
    #{
        input => 'temporal.api.workflowservice.v1.StartBatchOperationRequest',
        name => 'StartBatchOperation',
        output => 'temporal.api.workflowservice.v1.StartBatchOperationResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/batch-operations/{job_id}\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/batch-operations/{job_id}\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 83, 116, 97, 114,
                116, 66, 97, 116, 99, 104, 79, 112, 101, 114, 97, 116, 105, 111, 110, 82, 101, 113,
                117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('StopBatchOperation') ->
    #{
        input => 'temporal.api.workflowservice.v1.StopBatchOperationRequest',
        name => 'StopBatchOperation',
        output => 'temporal.api.workflowservice.v1.StopBatchOperationResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/batch-operations/{job_id}/stop\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/batch-operations/{job_id}/stop\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 83, 116, 111, 112,
                66, 97, 116, 99, 104, 79, 112, 101, 114, 97, 116, 105, 111, 110, 82, 101, 113, 117,
                101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DescribeBatchOperation') ->
    #{
        input => 'temporal.api.workflowservice.v1.DescribeBatchOperationRequest',
        name => 'DescribeBatchOperation',
        output => 'temporal.api.workflowservice.v1.DescribeBatchOperationResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/batch-operations/{job_id}\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/batch-operations/{job_id}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 115, 99,
                114, 105, 98, 101, 66, 97, 116, 99, 104, 79, 112, 101, 114, 97, 116, 105, 111, 110,
                82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListBatchOperations') ->
    #{
        input => 'temporal.api.workflowservice.v1.ListBatchOperationsRequest',
        name => 'ListBatchOperations',
        output => 'temporal.api.workflowservice.v1.ListBatchOperationsResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/batch-operations\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/batch-operations\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                66, 97, 116, 99, 104, 79, 112, 101, 114, 97, 116, 105, 111, 110, 115, 82, 101, 113,
                117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('PollNexusTaskQueue') ->
    #{
        input => 'temporal.api.workflowservice.v1.PollNexusTaskQueueRequest',
        name => 'PollNexusTaskQueue',
        output => 'temporal.api.workflowservice.v1.PollNexusTaskQueueResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 80, 111, 108, 108,
                78, 101, 120, 117, 115, 84, 97, 115, 107, 81, 117, 101, 117, 101, 82, 101, 113, 117,
                101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RespondNexusTaskCompleted') ->
    #{
        input => 'temporal.api.workflowservice.v1.RespondNexusTaskCompletedRequest',
        name => 'RespondNexusTaskCompleted',
        output => 'temporal.api.workflowservice.v1.RespondNexusTaskCompletedResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 112,
                111, 110, 100, 78, 101, 120, 117, 115, 84, 97, 115, 107, 67, 111, 109, 112, 108,
                101, 116, 101, 100, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RespondNexusTaskFailed') ->
    #{
        input => 'temporal.api.workflowservice.v1.RespondNexusTaskFailedRequest',
        name => 'RespondNexusTaskFailed',
        output => 'temporal.api.workflowservice.v1.RespondNexusTaskFailedResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 112,
                111, 110, 100, 78, 101, 120, 117, 115, 84, 97, 115, 107, 70, 97, 105, 108, 101, 100,
                82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('UpdateActivityOptions') ->
    #{
        input => 'temporal.api.workflowservice.v1.UpdateActivityOptionsRequest',
        name => 'UpdateActivityOptions',
        output => 'temporal.api.workflowservice.v1.UpdateActivityOptionsResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/activities/update-options\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/activities/update-options\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 85, 112, 100, 97,
                116, 101, 65, 99, 116, 105, 118, 105, 116, 121, 79, 112, 116, 105, 111, 110, 115,
                82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('UpdateWorkflowExecutionOptions') ->
    #{
        input => 'temporal.api.workflowservice.v1.UpdateWorkflowExecutionOptionsRequest',
        name => 'UpdateWorkflowExecutionOptions',
        output => 'temporal.api.workflowservice.v1.UpdateWorkflowExecutionOptionsResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/update-options\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/update-options\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 85, 112, 100, 97,
                116, 101, 87, 111, 114, 107, 102, 108, 111, 119, 69, 120, 101, 99, 117, 116, 105,
                111, 110, 79, 112, 116, 105, 111, 110, 115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('PauseActivity') ->
    #{
        input => 'temporal.api.workflowservice.v1.PauseActivityRequest',
        name => 'PauseActivity',
        output => 'temporal.api.workflowservice.v1.PauseActivityResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/activities/pause\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/activities/pause\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 80, 97, 117, 115,
                101, 65, 99, 116, 105, 118, 105, 116, 121, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('UnpauseActivity') ->
    #{
        input => 'temporal.api.workflowservice.v1.UnpauseActivityRequest',
        name => 'UnpauseActivity',
        output => 'temporal.api.workflowservice.v1.UnpauseActivityResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/activities/unpause\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/activities/unpause\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 85, 110, 112, 97,
                117, 115, 101, 65, 99, 116, 105, 118, 105, 116, 121, 82, 101, 113, 117, 101, 115,
                116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ResetActivity') ->
    #{
        input => 'temporal.api.workflowservice.v1.ResetActivityRequest',
        name => 'ResetActivity',
        output => 'temporal.api.workflowservice.v1.ResetActivityResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/activities/reset\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/activities/reset\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 115, 101,
                116, 65, 99, 116, 105, 118, 105, 116, 121, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('CreateWorkflowRule') ->
    #{
        input => 'temporal.api.workflowservice.v1.CreateWorkflowRuleRequest',
        name => 'CreateWorkflowRule',
        output => 'temporal.api.workflowservice.v1.CreateWorkflowRuleResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workflow-rules\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workflow-rules\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 67, 114, 101, 97,
                116, 101, 87, 111, 114, 107, 102, 108, 111, 119, 82, 117, 108, 101, 82, 101, 113,
                117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DescribeWorkflowRule') ->
    #{
        input => 'temporal.api.workflowservice.v1.DescribeWorkflowRuleRequest',
        name => 'DescribeWorkflowRule',
        output => 'temporal.api.workflowservice.v1.DescribeWorkflowRuleResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/workflow-rules/{rule_id}\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/workflow-rules/{rule_id}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 115, 99,
                114, 105, 98, 101, 87, 111, 114, 107, 102, 108, 111, 119, 82, 117, 108, 101, 82,
                101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DeleteWorkflowRule') ->
    #{
        input => 'temporal.api.workflowservice.v1.DeleteWorkflowRuleRequest',
        name => 'DeleteWorkflowRule',
        output => 'temporal.api.workflowservice.v1.DeleteWorkflowRuleResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ delete : \"/namespaces/{namespace}/workflow-rules/{rule_id}\" additional_bindings { delete : \"/api/v1/namespaces/{namespace}/workflow-rules/{rule_id}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 108, 101,
                116, 101, 87, 111, 114, 107, 102, 108, 111, 119, 82, 117, 108, 101, 82, 101, 113,
                117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListWorkflowRules') ->
    #{
        input => 'temporal.api.workflowservice.v1.ListWorkflowRulesRequest',
        name => 'ListWorkflowRules',
        output => 'temporal.api.workflowservice.v1.ListWorkflowRulesResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/workflow-rules\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/workflow-rules\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                87, 111, 114, 107, 102, 108, 111, 119, 82, 117, 108, 101, 115, 82, 101, 113, 117,
                101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('TriggerWorkflowRule') ->
    #{
        input => 'temporal.api.workflowservice.v1.TriggerWorkflowRuleRequest',
        name => 'TriggerWorkflowRule',
        output => 'temporal.api.workflowservice.v1.TriggerWorkflowRuleResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workflows/{execution.workflow_id}/trigger-rule\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workflows/{execution.workflow_id}/trigger-rule\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 84, 114, 105, 103,
                103, 101, 114, 87, 111, 114, 107, 102, 108, 111, 119, 82, 117, 108, 101, 82, 101,
                113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RecordWorkerHeartbeat') ->
    #{
        input => 'temporal.api.workflowservice.v1.RecordWorkerHeartbeatRequest',
        name => 'RecordWorkerHeartbeat',
        output => 'temporal.api.workflowservice.v1.RecordWorkerHeartbeatResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workers/heartbeat\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workers/heartbeat\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 99, 111,
                114, 100, 87, 111, 114, 107, 101, 114, 72, 101, 97, 114, 116, 98, 101, 97, 116, 82,
                101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListWorkers') ->
    #{
        input => 'temporal.api.workflowservice.v1.ListWorkersRequest',
        name => 'ListWorkers',
        output => 'temporal.api.workflowservice.v1.ListWorkersResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/workers\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/workers\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                87, 111, 114, 107, 101, 114, 115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('UpdateTaskQueueConfig') ->
    #{
        input => 'temporal.api.workflowservice.v1.UpdateTaskQueueConfigRequest',
        name => 'UpdateTaskQueueConfig',
        output => 'temporal.api.workflowservice.v1.UpdateTaskQueueConfigResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/task-queues/{task_queue}/update-config\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/task-queues/{task_queue}/update-config\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 85, 112, 100, 97,
                116, 101, 84, 97, 115, 107, 81, 117, 101, 117, 101, 67, 111, 110, 102, 105, 103, 82,
                101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('FetchWorkerConfig') ->
    #{
        input => 'temporal.api.workflowservice.v1.FetchWorkerConfigRequest',
        name => 'FetchWorkerConfig',
        output => 'temporal.api.workflowservice.v1.FetchWorkerConfigResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workers/fetch-config\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workers/fetch-config\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 70, 101, 116, 99,
                104, 87, 111, 114, 107, 101, 114, 67, 111, 110, 102, 105, 103, 82, 101, 113, 117,
                101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('UpdateWorkerConfig') ->
    #{
        input => 'temporal.api.workflowservice.v1.UpdateWorkerConfigRequest',
        name => 'UpdateWorkerConfig',
        output => 'temporal.api.workflowservice.v1.UpdateWorkerConfigResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/namespaces/{namespace}/workers/update-config\" body : \"*\" additional_bindings { post : \"/api/v1/namespaces/{namespace}/workers/update-config\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 85, 112, 100, 97,
                116, 101, 87, 111, 114, 107, 101, 114, 67, 111, 110, 102, 105, 103, 82, 101, 113,
                117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DescribeWorker') ->
    #{
        input => 'temporal.api.workflowservice.v1.DescribeWorkerRequest',
        name => 'DescribeWorker',
        output => 'temporal.api.workflowservice.v1.DescribeWorkerResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/namespaces/{namespace}/workers/describe/{worker_instance_key}\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/workers/describe/{worker_instance_key}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 119, 111, 114, 107, 102,
                108, 111, 119, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 115, 99,
                114, 105, 98, 101, 87, 111, 114, 107, 101, 114, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.workflowservice.v1.WorkflowService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('AddSearchAttributes') ->
    #{
        input => 'temporal.api.operatorservice.v1.AddSearchAttributesRequest',
        name => 'AddSearchAttributes',
        output => 'temporal.api.operatorservice.v1.AddSearchAttributesResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 111, 112, 101, 114, 97,
                116, 111, 114, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 65, 100, 100, 83,
                101, 97, 114, 99, 104, 65, 116, 116, 114, 105, 98, 117, 116, 101, 115, 82, 101, 113,
                117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.operatorservice.v1.OperatorService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RemoveSearchAttributes') ->
    #{
        input => 'temporal.api.operatorservice.v1.RemoveSearchAttributesRequest',
        name => 'RemoveSearchAttributes',
        output => 'temporal.api.operatorservice.v1.RemoveSearchAttributesResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 111, 112, 101, 114, 97,
                116, 111, 114, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 109, 111,
                118, 101, 83, 101, 97, 114, 99, 104, 65, 116, 116, 114, 105, 98, 117, 116, 101, 115,
                82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.operatorservice.v1.OperatorService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListSearchAttributes') ->
    #{
        input => 'temporal.api.operatorservice.v1.ListSearchAttributesRequest',
        name => 'ListSearchAttributes',
        output => 'temporal.api.operatorservice.v1.ListSearchAttributesResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/cluster/namespaces/{namespace}/search-attributes\" additional_bindings { get : \"/api/v1/namespaces/{namespace}/search-attributes\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 111, 112, 101, 114, 97,
                116, 111, 114, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                83, 101, 97, 114, 99, 104, 65, 116, 116, 114, 105, 98, 117, 116, 101, 115, 82, 101,
                113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.operatorservice.v1.OperatorService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DeleteNamespace') ->
    #{
        input => 'temporal.api.operatorservice.v1.DeleteNamespaceRequest',
        name => 'DeleteNamespace',
        output => 'temporal.api.operatorservice.v1.DeleteNamespaceResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 111, 112, 101, 114, 97,
                116, 111, 114, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 108, 101,
                116, 101, 78, 97, 109, 101, 115, 112, 97, 99, 101, 82, 101, 113, 117, 101, 115,
                116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.operatorservice.v1.OperatorService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('AddOrUpdateRemoteCluster') ->
    #{
        input => 'temporal.api.operatorservice.v1.AddOrUpdateRemoteClusterRequest',
        name => 'AddOrUpdateRemoteCluster',
        output => 'temporal.api.operatorservice.v1.AddOrUpdateRemoteClusterResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 111, 112, 101, 114, 97,
                116, 111, 114, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 65, 100, 100, 79,
                114, 85, 112, 100, 97, 116, 101, 82, 101, 109, 111, 116, 101, 67, 108, 117, 115,
                116, 101, 114, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.operatorservice.v1.OperatorService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('RemoveRemoteCluster') ->
    #{
        input => 'temporal.api.operatorservice.v1.RemoveRemoteClusterRequest',
        name => 'RemoveRemoteCluster',
        output => 'temporal.api.operatorservice.v1.RemoveRemoteClusterResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 111, 112, 101, 114, 97,
                116, 111, 114, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 82, 101, 109, 111,
                118, 101, 82, 101, 109, 111, 116, 101, 67, 108, 117, 115, 116, 101, 114, 82, 101,
                113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.operatorservice.v1.OperatorService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListClusters') ->
    #{
        input => 'temporal.api.operatorservice.v1.ListClustersRequest',
        name => 'ListClusters',
        output => 'temporal.api.operatorservice.v1.ListClustersResponse',
        opts => [],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 111, 112, 101, 114, 97,
                116, 111, 114, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                67, 108, 117, 115, 116, 101, 114, 115, 82, 101, 113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.operatorservice.v1.OperatorService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('GetNexusEndpoint') ->
    #{
        input => 'temporal.api.operatorservice.v1.GetNexusEndpointRequest',
        name => 'GetNexusEndpoint',
        output => 'temporal.api.operatorservice.v1.GetNexusEndpointResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/cluster/nexus/endpoints/{id}\" additional_bindings { get : \"/api/v1/nexus/endpoints/{id}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 111, 112, 101, 114, 97,
                116, 111, 114, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 71, 101, 116, 78,
                101, 120, 117, 115, 69, 110, 100, 112, 111, 105, 110, 116, 82, 101, 113, 117, 101,
                115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.operatorservice.v1.OperatorService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('CreateNexusEndpoint') ->
    #{
        input => 'temporal.api.operatorservice.v1.CreateNexusEndpointRequest',
        name => 'CreateNexusEndpoint',
        output => 'temporal.api.operatorservice.v1.CreateNexusEndpointResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/cluster/nexus/endpoints\" body : \"*\" additional_bindings { post : \"/api/v1/nexus/endpoints\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 111, 112, 101, 114, 97,
                116, 111, 114, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 67, 114, 101, 97,
                116, 101, 78, 101, 120, 117, 115, 69, 110, 100, 112, 111, 105, 110, 116, 82, 101,
                113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.operatorservice.v1.OperatorService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('UpdateNexusEndpoint') ->
    #{
        input => 'temporal.api.operatorservice.v1.UpdateNexusEndpointRequest',
        name => 'UpdateNexusEndpoint',
        output => 'temporal.api.operatorservice.v1.UpdateNexusEndpointResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ post : \"/cluster/nexus/endpoints/{id}/update\" body : \"*\" additional_bindings { post : \"/api/v1/nexus/endpoints/{id}/update\" body : \"*\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 111, 112, 101, 114, 97,
                116, 111, 114, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 85, 112, 100, 97,
                116, 101, 78, 101, 120, 117, 115, 69, 110, 100, 112, 111, 105, 110, 116, 82, 101,
                113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.operatorservice.v1.OperatorService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('DeleteNexusEndpoint') ->
    #{
        input => 'temporal.api.operatorservice.v1.DeleteNexusEndpointRequest',
        name => 'DeleteNexusEndpoint',
        output => 'temporal.api.operatorservice.v1.DeleteNexusEndpointResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ delete : \"/cluster/nexus/endpoints/{id}\" additional_bindings { delete : \"/api/v1/nexus/endpoints/{id}\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 111, 112, 101, 114, 97,
                116, 111, 114, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 68, 101, 108, 101,
                116, 101, 78, 101, 120, 117, 115, 69, 110, 100, 112, 111, 105, 110, 116, 82, 101,
                113, 117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.operatorservice.v1.OperatorService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    };
info('ListNexusEndpoints') ->
    #{
        input => 'temporal.api.operatorservice.v1.ListNexusEndpointsRequest',
        name => 'ListNexusEndpoints',
        output => 'temporal.api.operatorservice.v1.ListNexusEndpointsResponse',
        opts => [
            {'google...api...http',
                {uninterpreted,
                    "{ get : \"/cluster/nexus/endpoints\" additional_bindings { get : \"/api/v1/nexus/endpoints\" } }"}}
        ],
        msg_type =>
            <<116, 101, 109, 112, 111, 114, 97, 108, 46, 97, 112, 105, 46, 111, 112, 101, 114, 97,
                116, 111, 114, 115, 101, 114, 118, 105, 99, 101, 46, 118, 49, 46, 76, 105, 115, 116,
                78, 101, 120, 117, 115, 69, 110, 100, 112, 111, 105, 110, 116, 115, 82, 101, 113,
                117, 101, 115, 116>>,
        input_stream => false,
        output_stream => false,
        service_fqname => 'temporal.api.operatorservice.v1.OperatorService',
        content_type =>
            <<97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 47, 103, 114, 112, 99, 43, 112,
                114, 111, 116, 111>>
    }.
