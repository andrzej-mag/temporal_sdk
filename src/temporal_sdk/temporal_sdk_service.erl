-module(temporal_sdk_service).

% elp:ignore W0012 W0040
-moduledoc {file, "../../docs/temporal_sdk/operator/-module.md"}.

-export([
    get_workflow_history/2,
    get_workflow_history/3,

    get_workflow_history_reverse/2,
    get_workflow_history_reverse/3,

    describe_workflow/2,
    describe_workflow/3,

    list_open_workflows/1,
    list_open_workflows/2,
    list_closed_workflows/1,
    list_closed_workflows/2,
    list_workflows/1,
    list_workflows/2,
    list_archived_workflows/1,
    list_archived_workflows/2,

    signal_workflow/3,
    signal_workflow/4,

    query_workflow/3,
    query_workflow/4,

    update_workflow/4
]).

-include("proto.hrl").

-type get_workflow_history_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution execution = 2;
    | {maximum_page_size, pos_integer()}
    | {next_page_token, binary()}
    | {wait_new_event, boolean()}
    | {history_event_filter_type, ?TEMPORAL_SPEC:'temporal.api.enums.v1.HistoryEventFilterType'()}
    %% SDK
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryReverseRequest'()}
    | {response_type, temporal_sdk:response_type()}
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
].
-export_type([get_workflow_history_opts/0]).

-type get_workflow_history_reverse_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution execution = 2;
    | {maximum_page_size, pos_integer()}
    | {next_page_token, binary()}
    %% SDK
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryReverseRequest'()}
    | {response_type, temporal_sdk:response_type()}
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
].
-export_type([get_workflow_history_reverse_opts/0]).

-type describe_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% SDK
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.DescribeWorkflowExecutionRequest'()}
    | {response_type, temporal_sdk:response_type()}
].
-export_type([describe_workflow_opts/0]).

-type list_open_workflows_opts() :: [
    {namespace, unicode:chardata()}
    | {maximum_page_size, pos_integer()}
    | {next_page_token, binary()}
    | {start_time_filter, ?TEMPORAL_SPEC:'temporal.api.filter.v1.StartTimeFilter'()}
    | {filters,
        {execution_filter, ?TEMPORAL_SPEC:'temporal.api.filter.v1.WorkflowExecutionFilter'()}
        | {type_filter, ?TEMPORAL_SPEC:'temporal.api.filter.v1.WorkflowTypeFilter'()}}
    %% SDK
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
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ListArchivedWorkflowExecutionsRequest'()}
    | {response_type, temporal_sdk:response_type()}
].
-export_type([list_archived_workflows_opts/0]).

-type signal_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution workflow_execution = 2;
    %% string signal_name = 3;
    | {input, temporal_sdk:term_to_payloads()}
    | {identity, unicode:chardata()}
    | {request_id, unicode:chardata()}
    | {header, temporal_sdk:term_to_mapstring_payload()}
    %% repeated temporal.api.common.v1.Link links = 10;
    %% SDK
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.SignalWorkflowExecutionRequest'()}
    | {response_type, temporal_sdk:response_type()}
].
-export_type([signal_workflow_opts/0]).

-type query_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution execution = 2;
    %% string query_type = 1;
    | {query_args, temporal_sdk:term_to_payloads()}
    | {header, temporal_sdk:term_to_mapstring_payload()}
    | {query_reject_condition, ?TEMPORAL_SPEC:'temporal.api.enums.v1.QueryRejectCondition'()}
    %% SDK
    | {raw_request, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.QueryWorkflowRequest'()}
    | {response_type, temporal_sdk:response_type()}
].
-export_type([query_workflow_opts/0]).

-type update_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution execution = 2;
    | {first_execution_run_id, unicode:chardata()}
    %% temporal.api.update.v1.WaitPolicy wait_policy:
    | {wait_for_stage,
        ?TEMPORAL_SPEC:'temporal.api.enums.v1.UpdateWorkflowExecutionLifecycleStage'()}
    %% temporal.api.update.v1.Request request meta:
    | {update_id, unicode:chardata()}
    %% string identity = 2;
    %% temporal.api.update.v1.Request request input:
    | {header, temporal_sdk:term_to_mapstring_payload()}
    %% string name = 2;
    | {args, temporal_sdk:term_to_payloads()}
    %% SDK
    | {raw_request, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.QueryWorkflowRequest'()}
    | {response_type, temporal_sdk:response_type()}
].
-export_type([update_workflow_opts/0]).

%% -------------------------------------------------------------------------------------------------
%% Temporal services commands

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
        {raw_request, map, #{}},
        {response_type, atom, call_formatted},
        {grpc_opts, map, DefaultGrpcOpts, merge}
    ],
    temporal_sdk_api_common:run_request(
        Cluster,
        Opts,
        [{execution, map, WorkflowExecution} | DefaultOpts],
        'GetWorkflowExecutionHistory',
        'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryResponse'
    ).

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
        {raw_request, map, #{}},
        {response_type, atom, call_formatted},
        {grpc_opts, map, DefaultGrpcOpts, merge}
    ],
    temporal_sdk_api_common:run_request(
        Cluster,
        Opts,
        [{execution, map, WorkflowExecution} | DefaultOpts],
        'GetWorkflowExecutionHistoryReverse',
        'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryReverseResponse'
    ).

-spec describe_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecution :: temporal_sdk:workflow_execution()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.DescribeWorkflowExecutionResponse'()}
    | temporal_sdk:response().
describe_workflow(Cluster, WorkflowExecution) ->
    describe_workflow(Cluster, WorkflowExecution, []).

-spec describe_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecution :: temporal_sdk:workflow_execution(),
    Opts :: describe_workflow_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.DescribeWorkflowExecutionResponse'()}
    | temporal_sdk:response().
describe_workflow(Cluster, WorkflowExecution, Opts) ->
    DefaultOpts = [
        {namespace, unicode, "default"},
        %% SDK
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    maybe
        {ok, ApiCtx} ?= temporal_sdk_api_context:build(Cluster),
        {ok, FullOpts} ?= temporal_sdk_utils_opts:build(DefaultOpts, Opts, ApiCtx),
        {RawRequest, O1} = maps:take(raw_request, FullOpts),
        {ResponseType, O2} = maps:take(response_type, O1),
        Req = maps:merge(O2#{execution => WorkflowExecution}, RawRequest),
        Response =
            temporal_sdk_api:request('DescribeWorkflowExecution', Cluster, Req, ResponseType, #{}),
        temporal_sdk_api_common:format_response(
            'temporal.api.workflowservice.v1.DescribeWorkflowExecutionResponse',
            ResponseType,
            Response,
            ApiCtx
        )
    end.

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
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    temporal_sdk_api_common:run_request(
        Cluster,
        Opts,
        DefaultOpts,
        'ListOpenWorkflowExecutions',
        'temporal.api.workflowservice.v1.ListOpenWorkflowExecutionsResponse'
    ).

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
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    temporal_sdk_api_common:run_request(
        Cluster,
        Opts,
        DefaultOpts,
        'ListClosedWorkflowExecutions',
        'temporal.api.workflowservice.v1.ListClosedWorkflowExecutionsResponse'
    ).

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
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    temporal_sdk_api_common:run_request(
        Cluster,
        Opts,
        DefaultOpts,
        'ListWorkflowExecutions',
        'temporal.api.workflowservice.v1.ListWorkflowExecutionsResponse'
    ).

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
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    temporal_sdk_api_common:run_request(
        Cluster,
        Opts,
        DefaultOpts,
        'ListArchivedWorkflowExecutions',
        'temporal.api.workflowservice.v1.ListArchivedWorkflowExecutionsResponse'
    ).

-spec signal_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecution :: temporal_sdk:workflow_execution(),
    SignalName :: unicode:chardata()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.SignalWorkflowExecutionResponse'()}
    | temporal_sdk:response().
signal_workflow(Cluster, WorkflowExecution, SignalName) ->
    signal_workflow(Cluster, WorkflowExecution, SignalName, []).

-spec signal_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecution :: temporal_sdk:workflow_execution(),
    SignalName :: unicode:chardata(),
    Opts :: signal_workflow_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.SignalWorkflowExecutionResponse'()}
    | temporal_sdk:response().
signal_workflow(Cluster, WorkflowExecution, SignalName, Opts) ->
    MsgName = 'temporal.api.workflowservice.v1.SignalWorkflowExecutionRequest',
    DefaultOpts =
        [
            {namespace, unicode, "default"},
            %% temporal.api.common.v1.WorkflowExecution workflow_execution = 2;
            %% string signal_name = 3;
            {input, payloads, '$_optional', {MsgName, input}},
            {identity, unicode, '$_optional'},
            {request_id, unicode, '$_optional'},
            {header, header, '$_optional', {MsgName, header}},
            %% repeated temporal.api.common.v1.Link links = 10;
            %% SDK
            {raw_request, map, #{}},
            {response_type, atom, call_formatted}
        ],
    maybe
        {ok, ApiCtx} ?= temporal_sdk_api_context:build(Cluster),
        {ok, FullOpts} ?= temporal_sdk_utils_opts:build(DefaultOpts, Opts, ApiCtx),
        {RawRequest, ReqFromOpts0} = maps:take(raw_request, FullOpts),
        {ResponseType, ReqFromOpts} = maps:take(response_type, ReqFromOpts0),
        Req1 = ReqFromOpts#{workflow_execution => WorkflowExecution},
        Req2 = temporal_sdk_api:put_identity(ApiCtx, MsgName, Req1),
        Req3 = temporal_sdk_api:put_id(ApiCtx, MsgName, request_id, Req2),
        Req = maps:merge(Req3, RawRequest#{signal_name => SignalName}),
        Response = temporal_sdk_api:request('SignalWorkflowExecution', ApiCtx, Req, ResponseType),
        temporal_sdk_api_common:format_response(
            'temporal.api.workflowservice.v1.SignalWorkflowExecutionResponse',
            ResponseType,
            Response,
            ApiCtx
        )
    else
        Err -> Err
    end.

-spec query_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecution :: temporal_sdk:workflow_execution(),
    QueryType :: unicode:chardata()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.QueryWorkflowResponse'()}
    | temporal_sdk:response().
query_workflow(Cluster, WorkflowExecution, QueryType) ->
    query_workflow(Cluster, WorkflowExecution, QueryType, []).

-spec query_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecution :: temporal_sdk:workflow_execution(),
    QueryType :: unicode:chardata(),
    Opts :: query_workflow_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.QueryWorkflowResponse'()}
    %% when response_type set to call_formatted:
    | {ok, #{
        query_result => temporal_sdk:term_from_payloads(),
        query_rejected => ?TEMPORAL_SPEC:'temporal.api.query.v1.QueryRejected'()
    }}
    %% when response_type set to call_formatted:
    | {error, Message :: unicode:chardata()}
    | temporal_sdk:response().
query_workflow(Cluster, WorkflowExecution, QueryType, Opts) ->
    MsgName = 'temporal.api.workflowservice.v1.QueryWorkflowRequest',
    DefaultOpts =
        [
            {namespace, unicode, "default"},
            %% temporal.api.common.v1.WorkflowExecution execution = 2;
            %% string query_type = 1;
            {query_args, payloads, '$_optional', {MsgName, [query, query_args]}},
            {header, mapstring_payload, '$_optional', {MsgName, [query, header]}},
            {query_reject_condition, atom, '$_optional'},
            %% SDK
            {raw_request, map, #{}},
            {response_type, atom, call_formatted}
        ],
    maybe
        {ok, ApiCtx} ?= temporal_sdk_api_context:build(Cluster),
        {ok, FullOpts} ?= temporal_sdk_utils_opts:build(DefaultOpts, Opts, ApiCtx),
        {RawRequest, ReqFromOpts1} = maps:take(raw_request, FullOpts),
        {ResponseType, ReqFromOpts2} = maps:take(response_type, ReqFromOpts1),
        ReqFromOpts = maps:without([query_args, header], ReqFromOpts2),
        Query = maps:merge(#{query_type => QueryType}, maps:with([query_args, header], FullOpts)),
        Req1 = ReqFromOpts#{execution => WorkflowExecution, query => Query},
        Req = maps:merge(Req1, RawRequest),
        Response = temporal_sdk_api:request('QueryWorkflow', ApiCtx, Req, ResponseType),
        temporal_sdk_api_common:format_response(
            'temporal.api.workflowservice.v1.QueryWorkflowResponse',
            ResponseType,
            Response,
            ApiCtx
        )
    else
        Err -> Err
    end.

-spec update_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecution :: temporal_sdk:workflow_execution(),
    Name :: unicode:chardata(),
    Opts :: update_workflow_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.UpdateWorkflowExecutionResponse'()}
    %% when response_type set to call_formatted:
    | {error, Message :: unicode:chardata()}
    | temporal_sdk:response().
update_workflow(Cluster, WorkflowExecution, Name, Opts) ->
    MsgName = 'temporal.api.workflowservice.v1.UpdateWorkflowExecutionRequest',
    DefaultOpts =
        [
            {namespace, unicode, "default"},
            %% temporal.api.common.v1.WorkflowExecution execution = 2;
            {first_execution_run_id, unicode, '$_optional'},
            {wait_for_stage, [atom, non_neg_integer],
                'UPDATE_WORKFLOW_EXECUTION_LIFECYCLE_STAGE_COMPLETED'},
            %% temporal.api.update.v1.Request request meta:
            {update_id, unicode, '$_optional'},
            %% string identity = 2;
            %% temporal.api.update.v1.Request request input:
            {header, mapstring_payload, '$_optional', {MsgName, [request, input, header]}},
            %% string name = 2;
            {args, payloads, '$_optional', {MsgName, [request, input, args]}},
            %% SDK
            {raw_request, map, #{}},
            {response_type, atom, call_formatted}
        ],
    maybe
        {ok, ApiCtx} ?= temporal_sdk_api_context:build(Cluster),
        {ok,
            #{
                raw_request := RawRequest,
                response_type := ResponseType,
                wait_for_stage := WaitForStage
            } =
                FullOpts} ?=
            temporal_sdk_utils_opts:build(DefaultOpts, Opts, ApiCtx),
        Req0 = maps:with([namespace, first_execution_run_id], FullOpts),
        Req1 = Req0#{
            workflow_execution => WorkflowExecution,
            wait_policy => #{lifecycle_stage => WaitForStage}
        },
        RMeta0 = maps:with([update_id], FullOpts),
        RMeta = temporal_sdk_api:put_identity(ApiCtx, MsgName, RMeta0),
        RInput0 = maps:with([header, args], FullOpts),
        RInput = RInput0#{name => Name},
        R = #{meta => RMeta, input => RInput},
        Req = maps:merge(Req1#{request => R}, RawRequest),
        Response = temporal_sdk_api:request('UpdateWorkflowExecution', ApiCtx, Req, ResponseType),
        temporal_sdk_api_common:format_response(
            'temporal.api.workflowservice.v1.UpdateWorkflowExecutionResponse',
            ResponseType,
            Response,
            ApiCtx
        )
    else
        Err -> Err
    end.
