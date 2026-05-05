-module(temporal_sdk_service).

% elp:ignore W0012 W0040 E1599
-moduledoc {file, "../../docs/temporal_sdk/service/-module.md"}.

-export([
    get_workflow_history/2,
    get_workflow_history/3,

    get_workflow_history_reverse/2,
    get_workflow_history_reverse/3,

    list_open_workflows/1,
    list_open_workflows/2,
    list_closed_workflows/1,
    list_closed_workflows/2,
    list_workflows/1,
    list_workflows/2,
    list_archived_workflows/1,
    list_archived_workflows/2
]).

-include("proto.hrl").

-define(DEFAULT_GRPC_OPTS, #{disable_telemetry => true}).

-type get_workflow_history_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution execution = 2;
    | {maximum_page_size, pos_integer()}
    | {next_page_token, binary()}
    | {wait_new_event, boolean()}
    | {history_event_filter_type, ?TEMPORAL_SPEC:'temporal.api.enums.v1.HistoryEventFilterType'()}
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryReverseRequest'()}
    | {response_type, temporal_sdk:response_type()}
].
-export_type([get_workflow_history_opts/0]).

-type get_workflow_history_reverse_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution execution = 2;
    | {maximum_page_size, pos_integer()}
    | {next_page_token, binary()}
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryReverseRequest'()}
    | {response_type, temporal_sdk:response_type()}
].
-export_type([get_workflow_history_reverse_opts/0]).

-type list_open_workflows_opts() :: [
    {namespace, unicode:chardata()}
    | {maximum_page_size, pos_integer()}
    | {next_page_token, binary()}
    | {start_time_filter, ?TEMPORAL_SPEC:'temporal.api.filter.v1.StartTimeFilter'()}
    | {filters,
        {execution_filter, ?TEMPORAL_SPEC:'temporal.api.filter.v1.WorkflowExecutionFilter'()}
        | {type_filter, ?TEMPORAL_SPEC:'temporal.api.filter.v1.WorkflowTypeFilter'()}}
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ListOpenWorkflowExecutionsRequest'()}
    | {response_type, temporal_sdk:response_type()}
].
-export_type([list_open_workflows_opts/0]).

-type list_closed_workflows_opts() :: [
    {namespace, unicode:chardata()}
    | {maximum_page_size, pos_integer()}
    | {next_page_token, binary()}
    | {start_time_filter, ?TEMPORAL_SPEC:'temporal.api.filter.v1.StartTimeFilter'()}
    | {filters,
        {execution_filter, ?TEMPORAL_SPEC:'temporal.api.filter.v1.WorkflowExecutionFilter'()}
        | {type_filter, ?TEMPORAL_SPEC:'temporal.api.filter.v1.WorkflowTypeFilter'()}
        | {status_filter, ?TEMPORAL_SPEC:'temporal.api.filter.v1.StatusFilter'()}}
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ListClosedWorkflowExecutionsRequest'()}
    | {response_type, temporal_sdk:response_type()}
].
-export_type([list_closed_workflows_opts/0]).

-type list_workflows_opts() :: [
    {namespace, unicode:chardata()}
    | {page_size, pos_integer()}
    | {next_page_token, binary()}
    | {query, unicode:chardata()}
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ListWorkflowExecutionsRequest'()}
    | {response_type, temporal_sdk:response_type()}
].
-export_type([list_workflows_opts/0]).

-type list_archived_workflows_opts() :: [
    {namespace, unicode:chardata()}
    | {page_size, pos_integer()}
    | {next_page_token, binary()}
    | {query, unicode:chardata()}
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ListArchivedWorkflowExecutionsRequest'()}
    | {response_type, temporal_sdk:response_type()}
].
-export_type([list_archived_workflows_opts/0]).

%% -------------------------------------------------------------------------------------------------
%% API

-spec get_workflow_history(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecution :: temporal_sdk:workflow_execution()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryResponse'()}
    | temporal_sdk:response().
get_workflow_history(Cluster, WorkflowExecution) ->
    get_workflow_history(Cluster, WorkflowExecution, []).

-spec get_workflow_history(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecution :: temporal_sdk:workflow_execution(),
    Opts :: get_workflow_history_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryResponse'()}
    | temporal_sdk:response().
get_workflow_history(Cluster, WorkflowExecution, Opts) ->
    IsRetryableFn = fun
        ({ok, _Result}, _RequestInfo, _Attempt) -> false;
        (_Error, _RequestInfo, _Attempt) -> true
    end,
    DefaultGrpcOpts = #{
        retry_policy => #{
            %% Maximum retry timeout: 47.5 seconds
            max_attempts => 50,
            backoff_coefficient => 2,
            initial_interval => 100,
            maximum_interval => 1_000,
            is_retryable => IsRetryableFn
        },
        timeout => 65_000
    },
    DefaultOpts = [
        {namespace, unicode, "default"},
        %% temporal.api.common.v1.WorkflowExecution execution = 2;
        {maximum_page_size, pos_integer, '$_optional'},
        {next_page_token, binary, '$_optional'},
        {wait_new_event, boolean, '$_optional'},
        {history_event_filter_type, atom, '$_optional'},
        %% SDK
        {grpc_opts, map, DefaultGrpcOpts, merge},
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    SName = 'GetWorkflowExecutionHistory',
    ReqMN = 'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryRequest',
    RspMN = 'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryResponse',
    Custom = [{workflow_execution, {execution, WorkflowExecution}}],
    temporal_sdk_api_common:run_request(Cluster, Opts, DefaultOpts, SName, ReqMN, RspMN, Custom).

-spec get_workflow_history_reverse(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecution :: temporal_sdk:workflow_execution()
) ->
    {ok,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryReverseResponse'()}
    | temporal_sdk:response().
get_workflow_history_reverse(Cluster, WorkflowExecution) ->
    get_workflow_history_reverse(Cluster, WorkflowExecution, []).

-spec get_workflow_history_reverse(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecution :: temporal_sdk:workflow_execution(),
    Opts :: get_workflow_history_reverse_opts()
) ->
    {ok,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryReverseResponse'()}
    | temporal_sdk:response().
get_workflow_history_reverse(Cluster, WorkflowExecution, Opts) ->
    IsRetryableFn = fun
        ({ok, _Result}, _RequestInfo, _Attempt) -> false;
        (_Error, _RequestInfo, _Attempt) -> true
    end,
    DefaultGrpcOpts = #{
        retry_policy => #{
            %% Maximum retry timeout: 47.5 seconds
            max_attempts => 50,
            backoff_coefficient => 2,
            initial_interval => 100,
            maximum_interval => 1_000,
            is_retryable => IsRetryableFn
        },
        timeout => 65_000
    },
    DefaultOpts = [
        {namespace, unicode, "default"},
        %% temporal.api.common.v1.WorkflowExecution execution = 2;
        {maximum_page_size, pos_integer, '$_optional'},
        {next_page_token, binary, '$_optional'},
        %% SDK
        {grpc_opts, map, DefaultGrpcOpts, merge},
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    SName = 'GetWorkflowExecutionHistoryReverse',
    ReqMN = 'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryReverseRequest',
    RspMN = 'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryReverseResponse',
    Custom = [{workflow_execution, {execution, WorkflowExecution}}],
    temporal_sdk_api_common:run_request(Cluster, Opts, DefaultOpts, SName, ReqMN, RspMN, Custom).

-spec list_open_workflows(
    Cluster :: temporal_sdk_cluster:cluster_name()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ListOpenWorkflowExecutionsResponse'()}
    | temporal_sdk:response().
list_open_workflows(Cluster) ->
    list_open_workflows(Cluster, []).

-spec list_open_workflows(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Opts :: list_open_workflows_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ListOpenWorkflowExecutionsResponse'()}
    | temporal_sdk:response().
list_open_workflows(Cluster, Opts) ->
    DefaultOpts = [
        {namespace, unicode, "default"},
        {maximum_page_size, pos_integer, '$_optional'},
        {next_page_token, binary, '$_optional'},
        {start_time_filter, map, '$_optional'},
        {filters, tuple, '$_optional'},
        %% SDK
        {grpc_opts, map, ?DEFAULT_GRPC_OPTS, merge},
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    SName = 'ListOpenWorkflowExecutions',
    ReqMN = 'temporal.api.workflowservice.v1.ListOpenWorkflowExecutionsRequest',
    RspMN = 'temporal.api.workflowservice.v1.ListOpenWorkflowExecutionsResponse',
    temporal_sdk_api_common:run_request(Cluster, Opts, DefaultOpts, SName, ReqMN, RspMN).

-spec list_closed_workflows(
    Cluster :: temporal_sdk_cluster:cluster_name()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ListClosedWorkflowExecutionsResponse'()}
    | temporal_sdk:response().
list_closed_workflows(Cluster) ->
    list_closed_workflows(Cluster, []).

-spec list_closed_workflows(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Opts :: list_closed_workflows_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ListClosedWorkflowExecutionsResponse'()}
    | temporal_sdk:response().
list_closed_workflows(Cluster, Opts) ->
    DefaultOpts = [
        {namespace, unicode, "default"},
        {maximum_page_size, pos_integer, '$_optional'},
        {next_page_token, binary, '$_optional'},
        {start_time_filter, map, '$_optional'},
        {filters, tuple, '$_optional'},
        %% SDK
        {grpc_opts, map, ?DEFAULT_GRPC_OPTS, merge},
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    SName = 'ListClosedWorkflowExecutions',
    ReqMN = 'temporal.api.workflowservice.v1.ListClosedWorkflowExecutionsRequest',
    RspMN = 'temporal.api.workflowservice.v1.ListClosedWorkflowExecutionsResponse',
    temporal_sdk_api_common:run_request(Cluster, Opts, DefaultOpts, SName, ReqMN, RspMN).

-spec list_workflows(
    Cluster :: temporal_sdk_cluster:cluster_name()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ListWorkflowExecutionsResponse'()}
    | temporal_sdk:response().
list_workflows(Cluster) ->
    list_workflows(Cluster, []).

-spec list_workflows(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Opts :: list_workflows_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ListWorkflowExecutionsResponse'()}
    | temporal_sdk:response().
list_workflows(Cluster, Opts) ->
    DefaultOpts = [
        {namespace, unicode, "default"},
        {page_size, pos_integer, '$_optional'},
        {next_page_token, binary, '$_optional'},
        {query, unicode, '$_optional'},
        %% SDK
        {grpc_opts, map, ?DEFAULT_GRPC_OPTS, merge},
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    SName = 'ListWorkflowExecutions',
    ReqMN = 'temporal.api.workflowservice.v1.ListWorkflowExecutionsRequest',
    RspMN = 'temporal.api.workflowservice.v1.ListWorkflowExecutionsResponse',
    temporal_sdk_api_common:run_request(Cluster, Opts, DefaultOpts, SName, ReqMN, RspMN).

-spec list_archived_workflows(
    Cluster :: temporal_sdk_cluster:cluster_name()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ListArchivedWorkflowExecutionsResponse'()}
    | temporal_sdk:response().
list_archived_workflows(Cluster) ->
    list_archived_workflows(Cluster, []).

-spec list_archived_workflows(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Opts :: list_archived_workflows_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ListArchivedWorkflowExecutionsResponse'()}
    | temporal_sdk:response().
list_archived_workflows(Cluster, Opts) ->
    DefaultOpts = [
        {namespace, unicode, "default"},
        {page_size, pos_integer, '$_optional'},
        {next_page_token, binary, '$_optional'},
        {query, unicode, '$_optional'},
        %% SDK
        {grpc_opts, map, ?DEFAULT_GRPC_OPTS, merge},
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    SName = 'ListArchivedWorkflowExecutions',
    ReqMN = 'temporal.api.workflowservice.v1.ListArchivedWorkflowExecutionsRequest',
    RspMN = 'temporal.api.workflowservice.v1.ListArchivedWorkflowExecutionsResponse',
    temporal_sdk_api_common:run_request(Cluster, Opts, DefaultOpts, SName, ReqMN, RspMN).
