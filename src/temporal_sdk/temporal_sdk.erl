-module(temporal_sdk).

% elp:ignore W0012 W0040 E1599
-moduledoc {file, "../../docs/temporal_sdk/-module.md"}.

%% Workflow
-export([
    start_workflow/3,
    start_workflow/4,

    await_workflow/2,
    await_workflow/3,

    wait_workflow/2,
    wait_workflow/3,

    describe_workflow/2,
    describe_workflow/3,

    get_workflow_state/2,
    get_workflow_state/3,

    get_workflow_history/2,
    get_workflow_history/3,

    cancel_workflow/2,
    cancel_workflow/3,

    delete_workflow/2,
    delete_workflow/3,

    query_workflow/3,
    query_workflow/4,

    reset_workflow/2,
    reset_workflow/3,

    signal_workflow/3,
    signal_workflow/4,

    terminate_workflow/2,
    terminate_workflow/3

    % TODO
    % update_workflow/4
    % 'PollWorkflowExecutionUpdate'
]).

%% utilities
-export([
    replay_json/3,
    replay_json/4,

    replay_file/3,
    replay_file/4,

    replay_task/4,
    replay_task/5,

    format_response/3,

    evict_workflow/2,
    evict_workflow/3
]).

-include("proto.hrl").
-include("sdk.hrl").
-include("src/executor/temporal_sdk_executor.hrl").

-define(DEFAULT_REPLAY_WORKER_OPTS, [
    disable_telemetry, {task_settings, [{sticky_execution, [{type, disabled}]}]}
]).

-define(DEFAULT_GRPC_OPTS, #{disable_telemetry => true}).

%% -------------------------------------------------------------------------------------------------
%% Common typespecs

-type serializable() :: dynamic().
-export_type([serializable/0]).

-type convertable() :: dynamic().
-export_type([convertable/0]).

-type deconverted() :: dynamic().
-export_type([deconverted/0]).

-type term_to_payload() :: convertable().
-export_type([term_to_payload/0]).

-type term_from_payload() :: deconverted().
-export_type([term_from_payload/0]).

-type term_to_payloads() :: [convertable()].
-export_type([term_to_payloads/0]).

-type term_from_payloads() :: [deconverted()].
-export_type([term_from_payloads/0]).

-type term_to_mapstring_payload() :: #{unicode:chardata() | atom() => term_to_payload()}.
-export_type([term_to_mapstring_payload/0]).

-type term_from_mapstring_payload() :: #{unicode:chardata() => term_from_payload()}.
-export_type([term_from_mapstring_payload/0]).

-type term_to_mapstring_payloads() :: #{unicode:chardata() | atom() => term_to_payloads()}.
-export_type([term_to_mapstring_payloads/0]).

-type term_from_mapstring_payloads() :: #{unicode:chardata() => term_from_payloads()}.
-export_type([term_from_mapstring_payloads/0]).

-type temporal_payload() :: ?TEMPORAL_SPEC:'temporal.api.common.v1.Payload'().
-export_type([temporal_payload/0]).

-type temporal_payloads() :: ?TEMPORAL_SPEC:'temporal.api.common.v1.Payloads'().
-export_type([temporal_payloads/0]).

-type temporal_mapstring_payload() :: #{unicode:chardata() => temporal_payload()}.
-export_type([temporal_mapstring_payload/0]).

-type temporal_mapstring_payloads() :: #{unicode:chardata() => temporal_payloads()}.
-export_type([temporal_mapstring_payloads/0]).

-type time_unit() :: millisecond | second | minute | hour | day.
-export_type([time_unit/0]).

-type time() ::
    {TimeLength :: number(), TimeUnit :: time_unit()} | TimeMilliseconds :: non_neg_integer().
-export_type([time/0]).

-type retry_policy() :: #{
    initial_interval => pos_integer(),
    backoff_coefficient => number(),
    maximum_interval => pos_integer(),
    maximum_attempts => pos_integer(),
    non_retryable_error_types => [unicode:chardata()]
}.
-export_type([retry_policy/0]).

-type user_metadata() :: #{summary => term_to_payload(), details => term_to_payload()}.
-export_type([user_metadata/0]).

-type workflow_execution() :: ?TEMPORAL_SPEC:'temporal.api.common.v1.WorkflowExecution'().
-export_type([workflow_execution/0]).

-type workflow_execution_or_id() :: workflow_execution() | WorkflowId :: unicode:chardata().
-export_type([workflow_execution_or_id/0]).

-type application_failure() :: #{
    %% Failure
    source => serializable(),
    message => serializable(),
    stack_trace => serializable(),
    encoded_attributes => term_to_payload(),
    %% ApplicationFailureInfo
    type => unicode:chardata(),
    non_retryable => boolean(),
    details => term_to_payloads(),
    next_retry_delay => time()
}.
-export_type([application_failure/0]).

-type application_failure_as_list() :: [
    %% Failure
    {source, serializable()}
    | {message, serializable()}
    | {stack_trace, serializable()}
    | {encoded_attributes, term_to_payload()}
    %% ApplicationFailureInfo
    | {type, unicode:chardata()}
    | {non_retryable, boolean()}
    | non_retryable
    | {details, term_to_payloads()}
    | {next_retry_delay, time()}
].
-export_type([application_failure_as_list/0]).

-type failure_from_temporal() :: #{
    source => unicode:chardata(),
    message => unicode:chardata(),
    stack_trace => unicode:chardata(),
    encoded_attributes => term_from_payload(),
    failure_info =>
        {atom(), map()}
        | {application_failure_info, #{
            type => unicode:chardata(),
            non_retryable => boolean(),
            details => term_from_payloads(),
            next_retry_delay => pos_integer()
        }}
}.
-export_type([failure_from_temporal/0]).

-type call_response_error() :: temporal_sdk_client:call_result_error().
-export_type([call_response_error/0]).

-type response_type() :: call_formatted | call | cast | msg.
-export_type([response_type/0]).

-type response() ::
    %% when response_type set to call_formatted:
    {ok, FormattedResponse :: map()}
    | {error, FormattedGrpcResponseErrorMessage :: unicode:chardata()}
    %% when response_type set to call, cast or msg:
    | temporal_sdk_client:result().
-export_type([response/0]).

%% -------------------------------------------------------------------------------------------------
%% Workflow typespecs

-doc #{group => "Workflow commands"}.
-type start_workflow_opts() :: [
    {namespace, unicode:chardata()}
    | {workflow_id, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowType workflow_type = 3;
    %% temporal.api.taskqueue.v1.TaskQueue task_queue = 4;
    | {input, term_to_payloads()}
    | {workflow_execution_timeout, time()}
    | {workflow_run_timeout, time()}
    | {workflow_task_timeout, time()}
    | {identity, unicode:chardata()}
    | {request_id, unicode:chardata()}
    | {workflow_id_reuse_policy, ?TEMPORAL_SPEC:'temporal.api.enums.v1.WorkflowIdReusePolicy'()}
    | {workflow_id_conflict_policy,
        ?TEMPORAL_SPEC:'temporal.api.enums.v1.WorkflowIdConflictPolicy'()}
    | {signal_name, unicode:chardata()}
    | {signal_input, term_to_payloads()}
    %% retry_policy is effective only with fail_task command???
    | {retry_policy, retry_policy()}
    | {cron_schedule, unicode:chardata()}
    | {memo, term_to_mapstring_payload()}
    | {search_attributes, term_to_mapstring_payload()}
    | {header, term_to_mapstring_payload()}
    | {request_eager_execution, boolean() | atom()}
    | request_eager_execution
    %% temporal.api.failure.v1.Failure continued_failure = 18;
    %% temporal.api.common.v1.Payloads last_completion_result = 19;
    | {workflow_start_delay, time()}
    %% repeated temporal.api.common.v1.Callback completion_callbacks = 21;
    | {user_metadata, user_metadata()}
    %% repeated temporal.api.common.v1.Link links = 24;
    | {versioning_override, ?TEMPORAL_SPEC:'temporal.api.workflow.v1.VersioningOverride'()}
    | {on_conflict_options, ?TEMPORAL_SPEC:'temporal.api.workflow.v1.OnConflictOptions'()}
    | {priority, ?TEMPORAL_SPEC:'temporal.api.common.v1.Priority'()}
    | {eager_worker_deployment_options,
        ?TEMPORAL_SPEC:'temporal.api.deployment.v1.WorkerDeploymentOptions'()}
    | {time_skipping_config, ?TEMPORAL_SPEC:'temporal.api.workflow.v1.TimeSkippingConfig'()}
    %% SDK
    | {eager_worker_id, temporal_sdk_worker:id()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.StartWorkflowExecutionRequest'()}
    | {await, true | time() | infinity}
    | await
    | {wait, true | time() | infinity}
    | wait
].
-export_type([start_workflow_opts/0]).

-doc #{group => "Workflow commands"}.
-type start_workflow_ret() ::
    #{
        request_id := unicode:chardata(),
        started := boolean(),
        workflow_execution := workflow_execution()
    }.
-export_type([start_workflow_ret/0]).

-doc #{group => "Workflow commands"}.
-type workflow_result() ::
    {completed,
        ?TEMPORAL_SPEC:'temporal.api.history.v1.WorkflowExecutionCompletedEventAttributes'()}
    | {canceled,
        ?TEMPORAL_SPEC:'temporal.api.history.v1.WorkflowExecutionCanceledEventAttributes'()}
    | {failed, ?TEMPORAL_SPEC:'temporal.api.history.v1.WorkflowExecutionFailedEventAttributes'()}
    | {continued_as_new,
        ?TEMPORAL_SPEC:'temporal.api.history.v1.WorkflowExecutionContinuedAsNewEventAttributes'()}
    | {timed_out,
        ?TEMPORAL_SPEC:'temporal.api.history.v1.WorkflowExecutionTimedOutEventAttributes'()}
    | {terminated,
        ?TEMPORAL_SPEC:'temporal.api.history.v1.WorkflowExecutionTerminatedEventAttributes'()}
    | {continued_as_new,
        ?TEMPORAL_SPEC:'temporal.api.history.v1.WorkflowExecutionContinuedAsNewEventAttributes'()}.
-export_type([workflow_result/0]).

-doc #{group => "Workflow commands"}.
-type await_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% SDK
    | {timeout, time() | infinity}
].
-export_type([await_workflow_opts/0]).

-doc #{group => "Workflow commands"}.
-type describe_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.DescribeWorkflowExecutionRequest'()}
    | {response_type, response_type()}
].
-export_type([describe_workflow_opts/0]).

-doc #{group => "Workflow commands"}.
-type get_workflow_state_ret() ::
    {ok,
        completed
        | failed
        | timed_out
        | terminated
        | canceled
        | continued_as_new
        | unspecified
        | running}
    | call_response_error().
-export_type([get_workflow_state_ret/0]).

-doc #{group => "Workflow commands"}.
-type get_workflow_history_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution execution = 2;
    | {maximum_page_size, pos_integer()}
    | {next_page_token, binary()}
    | {wait_new_event, boolean()}
    | {history_event_filter_type, ?TEMPORAL_SPEC:'temporal.api.enums.v1.HistoryEventFilterType'()}
    %% bool skip_archival = 7;
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryRequest'()}
    | {timeout, time() | infinity}
    | {await_all, boolean()}
    | await_all
    | {await_all_close, boolean()}
    | await_all_close
    | {await_close, boolean()}
    | await_close
    | {history_file, boolean() | file:name_all()}
    | history_file
    | {history_file_write_modes, [file:mode()]}
    | {json, boolean()}
    | json
].
-export_type([get_workflow_history_opts/0]).

-doc #{group => "Workflow commands"}.
-type delete_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution workflow_execution = 2;
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.DeleteWorkflowExecutionRequest'()}
    | {response_type, response_type()}
].
-export_type([delete_workflow_opts/0]).

-doc #{group => "Workflow commands"}.
-type cancel_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution workflow_execution = 2;
    | {identity, unicode:chardata()}
    | {request_id, unicode:chardata()}
    | {first_execution_run_id, unicode:chardata()}
    | {reason, unicode:chardata()}
    %% repeated temporal.api.common.v1.Link links = 7;
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.RequestCancelWorkflowExecutionRequest'()}
    | {response_type, response_type()}
].
-export_type([cancel_workflow_opts/0]).

-doc #{group => "Workflow commands"}.
-type query_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution execution = 2;
    %% string query_type = 1;
    | {query_args, term_to_payloads()}
    | {header, term_to_mapstring_payload()}
    | {query_reject_condition, ?TEMPORAL_SPEC:'temporal.api.enums.v1.QueryRejectCondition'()}
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.QueryWorkflowRequest'()}
    | {response_type, response_type()}
].
-export_type([query_workflow_opts/0]).

-doc #{group => "Workflow commands"}.
-type reset_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution workflow_execution = 2;
    | {reason, unicode:chardata()}
    | {workflow_task_finish_event_id, pos_integer()}
    | {request_id, unicode:chardata()}
    %% Deprecated. Use `options`.
    %% temporal.api.enums.v1.ResetReapplyType reset_reapply_type = 6 [deprecated = true];
    | {reset_reapply_exclude_types,
        ?TEMPORAL_SPEC:'temporal.api.enums.v1.ResetReapplyExcludeType'()}
    | {post_reset_operations, list()}
    | {identity, unicode:chardata()}
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ResetWorkflowExecutionRequest'()}
    | {response_type, response_type()}
].
-export_type([reset_workflow_opts/0]).

-doc #{group => "Workflow commands"}.
-type signal_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution workflow_execution = 2;
    %% string signal_name = 3;
    | {input, term_to_payloads()}
    | {identity, unicode:chardata()}
    | {request_id, unicode:chardata()}
    | {header, term_to_mapstring_payload()}
    %% repeated temporal.api.common.v1.Link links = 10;
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.SignalWorkflowExecutionRequest'()}
    | {response_type, response_type()}
].
-export_type([signal_workflow_opts/0]).

-doc #{group => "Workflow commands"}.
-type terminate_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution workflow_execution = 2;
    | {reason, unicode:chardata()}
    | {details, term_to_payloads()}
    | {identity, unicode:chardata()}
    | {first_execution_run_id, unicode:chardata()}
    %% repeated temporal.api.common.v1.Link links = 7;
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.TerminateWorkflowExecutionRequest'()}
    | {response_type, response_type()}
].
-export_type([terminate_workflow_opts/0]).

-doc #{group => "Workflow commands"}.
-type update_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowExecution execution = 2;
    | {first_execution_run_id, unicode:chardata()}
    %% temporal.api.update.v1.WaitPolicy wait_policy:
    | {wait_for_stage,
        ?TEMPORAL_SPEC:'temporal.api.enums.v1.UpdateWorkflowExecutionLifecycleStage'()}
    %% temporal.api.update.v1.Request request meta:
    | {update_id, unicode:chardata()}
    | {identity, unicode:chardata()}
    %% temporal.api.update.v1.Request request input:
    | {header, term_to_mapstring_payload()}
    %% string name = 2;
    | {args, term_to_payloads()}
    %% SDK
    | {grpc_opts, temporal_sdk_client:grpc_opts()}
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.UpdateWorkflowExecutionRequest'()}
    | {response_type, response_type()}
].
-export_type([update_workflow_opts/0]).

%% -------------------------------------------------------------------------------------------------
%% Utilities typespecs

-doc #{group => "Utility functions"}.
-type replay_workflow_opts() :: [
    {timeout, erlang:timeout()}
    | {client_opts, temporal_sdk_client:opts()}
    | {worker_id, term()}
    | {worker_opts, term()}
    | {task_overwrites, [{input, term_to_payloads()}]}
].

-doc #{group => "Utility functions"}.
-type replay_workflow_ret() ::
    {completed, Result :: term_to_payloads()}
    | {canceled, Details :: term_to_payloads()}
    | {failed, Failure :: application_failure() | application_failure_as_list()}
    | {error, Error :: temporal_sdk_telemetry:exception()}.
-export_type([replay_workflow_ret/0]).

-doc #{group => "Utility functions"}.
-type replay_json_ret() ::
    {ok, replay_workflow_ret()}
    | {error,
        Reason ::
            timeout
            | unclosed_history
            | malformed_history
            | invalid_cluster
            | {invalid_opts, map()}
            | {nondeterministic, map()}
            | term()}.
-export_type([replay_json_ret/0]).

-doc #{group => "Utility functions"}.
-type replay_task_opts() :: [
    {start_workflow_opts, start_workflow_opts()}
    | {replay_workflow_opts, replay_workflow_opts()}
    | {history_file, boolean() | file:name_all()}
    | history_file
    | {history_file_write_modes, [file:mode()]}
].
-export_type([replay_task_opts/0]).

-doc #{group => "Utility functions"}.
-type evict_workflow_opts() :: [
    {namespace, unicode:chardata()}
    %% SDK
    | {reason, atom()}
].
-export_type([evict_workflow_opts/0]).

%% -------------------------------------------------------------------------------------------------
%% Workflow commands

-doc #{group => "Workflow commands"}.
-spec start_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    TaskQueue :: unicode:chardata(),
    WorkflowType :: atom() | unicode:chardata()
) ->
    {ok, start_workflow_ret()}
    | {error, Reason :: map() | invalid_cluster}
    | call_response_error().
start_workflow(Cluster, TaskQueue, WorkflowType) ->
    % eqwalizer:ignore
    start_workflow(Cluster, TaskQueue, WorkflowType, []).

-doc #{group => "Workflow commands"}.
-spec start_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    TaskQueue :: unicode:chardata(),
    WorkflowType :: atom() | unicode:chardata(),
    Opts :: start_workflow_opts()
) ->
    %% when await is set:
    {ok, start_workflow_ret(), workflow_result()}
    %% when wait is set:
    | {start_workflow_ret(), workflow_result()}
    | no_return()
    %% regular return:
    | {ok, start_workflow_ret()}
    | {error, Reason :: map() | invalid_cluster}
    | call_response_error().
start_workflow(Cluster, TaskQueue, WorkflowType, Opts) when is_atom(WorkflowType) ->
    start_workflow(Cluster, TaskQueue, atom_to_list(WorkflowType), Opts);
start_workflow(Cluster, TaskQueue, WorkflowType, Opts) ->
    MsgName = 'temporal.api.workflowservice.v1.StartWorkflowExecutionRequest',
    DefaultOpts = [
        {namespace, unicode, "default"},
        {workflow_id, unicode,
            temporal_sdk_utils_path:string_path([WorkflowType, temporal_sdk_utils:uuid4()])},
        %% temporal.api.common.v1.WorkflowType workflow_type = 3;
        %% temporal.api.taskqueue.v1.TaskQueue task_queue = 4;
        {input, payloads, '$_optional', {MsgName, input}},
        {workflow_execution_timeout, duration, '$_optional'},
        {workflow_run_timeout, duration, '$_optional'},
        {workflow_task_timeout, duration, '$_optional'},
        {identity, unicode, '$_optional'},
        {request_id, unicode, '$_optional'},
        {workflow_id_reuse_policy, atom, '$_optional'},
        {workflow_id_conflict_policy, atom, '$_optional'},
        {signal_name, unicode, '$_optional'},
        {signal_input, payloads, '$_optional', {MsgName, signal_input}},
        {retry_policy, retry_policy, '$_optional'},
        {cron_schedule, unicode, '$_optional'},
        {memo, memo, '$_optional', {MsgName, [memo, fields]}},
        {search_attributes, search_attributes, '$_optional',
            {MsgName, [search_attributes, indexed_fields]}},
        {header, header, '$_optional', {MsgName, header}},
        {request_eager_execution, [boolean, atom], '$_optional'},
        {continued_failure, failure, '$_optional'},
        {last_completion_result, payloads, '$_optional', {MsgName, last_completion_result}},
        {workflow_start_delay, duration, '$_optional'},
        %% repeated temporal.api.common.v1.Callback completion_callbacks = 21;
        {user_metadata, user_metadata, '$_optional', {MsgName, user_metadata}},
        %% repeated temporal.api.common.v1.Link links = 24;
        {versioning_override, map, '$_optional'},
        {on_conflict_options, map, '$_optional'},
        {priority, map, '$_optional'},
        {eager_worker_deployment_options, map, '$_optional'},
        {time_skipping_config, map, '$_optional'},
        %% SDK
        {eager_worker_id, [atom, unicode], '$_optional'},
        {raw_request, map, #{}},
        {await, [time, infinity, boolean], '$_optional'},
        {wait, [time, infinity, boolean], '$_optional'}
    ],
    maybe
        {ok, #{client_opts := #{grpc_opts := #{codec := {Codec, _, _}}}} = ApiCtx1} ?=
            temporal_sdk_api_context:build(Cluster),
        {ok, FullOpts} ?= temporal_sdk_utils_opts:build(DefaultOpts, Opts, ApiCtx1),
        ok ?= check_opts(start_workflow, FullOpts),
        {RawRequest, ReqFromOpts1} = maps:take(raw_request, FullOpts),
        ReqFromOpts2 = maps:without([await, wait], ReqFromOpts1),
        {ok, ReqFromOpts3, ApiCtx} ?= is_allowed_eager_wf(ReqFromOpts2, ApiCtx1, Cluster),
        ReqFromOpts = maps:remove(eager_worker_id, ReqFromOpts3),
        Req1 = ReqFromOpts#{
            workflow_type => #{name => WorkflowType},
            task_queue => #{name => TaskQueue}
        },
        Req2 = temporal_sdk_api:put_identity(ApiCtx, MsgName, Req1),
        Req3 = temporal_sdk_api:put_id(ApiCtx, MsgName, request_id, Req2),
        Req = maps:merge(Req3, RawRequest),
        #{workflow_id := WorkflowId, request_id := RequestId} = Req,
        {ok, #{run_id := RunId, started := Started}} ?= do_start_workflow_start(ApiCtx, Req),
        Response = #{
            request_id => RequestId,
            started => Started,
            workflow_execution => #{run_id => RunId, workflow_id => Codec:cast(WorkflowId)}
        },
        do_start_workflow_fin(Cluster, FullOpts, Response)
    else
        MErr ->
            case proplists:get_value(wait, Opts, false) of
                false -> MErr;
                _ -> erlang:error(MErr, [Cluster, TaskQueue, WorkflowType, Opts])
            end
    end.

do_start_workflow_start(ApiCtx, Req) ->
    case do_start_workflow_req(ApiCtx, Req) of
        {ok, #{run_id := RunId, started := Started, eager_workflow_task := Task}} ->
            case temporal_sdk_poller_adapter_workflow_task_queue:handle_execute(ApiCtx, Task) of
                {ok, _ExecuteStatus} -> {ok, #{run_id => RunId, started => Started}};
                Err -> Err
            end;
        {ok, #{run_id := RunId, started := Started}} ->
            {ok, #{run_id => RunId, started => Started}};
        Err ->
            Err
    end.

do_start_workflow_req(ApiCtx, #{signal_name := _} = Req) ->
    temporal_sdk_api:request('SignalWithStartWorkflowExecution', ApiCtx, Req, call);
do_start_workflow_req(ApiCtx, #{} = Req) ->
    temporal_sdk_api:request('StartWorkflowExecution', ApiCtx, Req, call).

do_start_workflow_fin(Cluster, #{await := true, namespace := NS}, #{workflow_execution := WE} = R) ->
    case await_workflow(Cluster, WE, [{namespace, NS}, {timeout, infinity}]) of
        {ok, AR} -> {ok, R, AR};
        Err -> Err
    end;
do_start_workflow_fin(Cluster, #{await := T, namespace := NS}, #{workflow_execution := WE} = R) ->
    case await_workflow(Cluster, WE, [{namespace, NS}, {timeout, T}]) of
        {ok, AR} -> {ok, R, AR};
        Err -> Err
    end;
do_start_workflow_fin(Cluster, #{wait := true, namespace := NS}, #{workflow_execution := WE} = R) ->
    {R, wait_workflow(Cluster, WE, [{namespace, NS}, {timeout, infinity}])};
do_start_workflow_fin(Cluster, #{wait := T, namespace := NS}, #{workflow_execution := WE} = R) ->
    {R, wait_workflow(Cluster, WE, [{namespace, NS}, {timeout, T}])};
do_start_workflow_fin(_Cluster, _Opts, Response) ->
    {ok, Response}.

is_allowed_eager_wf(#{request_eager_execution := false} = Opts, ApiCtx, _Cluster) ->
    {ok, Opts, ApiCtx};
is_allowed_eager_wf(
    #{request_eager_execution := REE, eager_worker_id := WId} = Opts, ApiCtx, Cluster
) when REE =:= true; REE =:= auto ->
    NodeCounters = temporal_sdk_node:get_counters(node),
    OSCounters = temporal_sdk_node:get_counters(os),
    maybe
        {ok, ClusterCounters} ?= temporal_sdk_cluster:get_counters(Cluster),
        {ok, {#{limits := Limits} = WOpts, #{worker := WCounters}}} ?=
            temporal_sdk_worker_opts:get_state(Cluster, workflow, WId),
        LimiterCounters = #{
            node => NodeCounters, os => OSCounters, cluster => ClusterCounters, worker => WCounters
        },
        {ok, Checks} ?= temporal_sdk_limiter:build_checks(Limits, LimiterCounters),
        case temporal_sdk_limiter:is_allowed(Checks) of
            true ->
                case
                    temporal_sdk_api_context:add_limiter_counters(ApiCtx, workflow, LimiterCounters)
                of
                    AC when is_map(AC) -> {ok, Opts, AC#{worker_opts => WOpts}};
                    Err -> {error, Err}
                end;
            LimitedBy ->
                case REE of
                    auto ->
                        {ok, Opts#{request_eager_execution := false}, ApiCtx};
                    true ->
                        {error, #{reason => rate_limited, limited_by => LimitedBy}}
                end
        end
    end;
is_allowed_eager_wf(#{request_eager_execution := Invalid}, _ApiCtx, _Cluster) ->
    {error, #{reason => "request_eager_execution set to invalid value.", invalid_value => Invalid}};
is_allowed_eager_wf(Opts, ApiCtx, _Cluster) ->
    {ok, Opts, ApiCtx}.

-doc #{group => "Workflow commands"}.
-spec await_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id()
) ->
    {ok, workflow_result()}
    | {error, Reason :: map() | invalid_cluster}
    | call_response_error().
await_workflow(Cluster, WorkflowExecutionOrId) ->
    await_workflow(Cluster, WorkflowExecutionOrId, []).

-doc #{group => "Workflow commands"}.
-spec await_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    Opts :: await_workflow_opts()
) ->
    {ok, workflow_result()}
    | {error, Reason :: map() | invalid_cluster}
    | call_response_error().
await_workflow(Cluster, WorkflowExecutionOrId, Opts) ->
    DefaultOpts = [
        {namespace, unicode, "default"},
        %% SDK
        {timeout, [time, infinity], infinity}
    ],
    maybe
        {ok, ApiCtx} ?= temporal_sdk_api_context:build(Cluster),
        {ok, LOpts} ?= temporal_sdk_utils_opts:build(DefaultOpts, Opts),
        GetOpts = [await_close] ++ proplists:from_map(LOpts),
        {ok, [ClosingEvent]} ?= get_workflow_history(Cluster, WorkflowExecutionOrId, GetOpts),
        temporal_sdk_api_history:workflow_execution_result(ClosingEvent, ApiCtx)
    else
        {ok, InvalidResponse} ->
            {error, #{
                reason => "Unhandled get_workflow_history/3 response.",
                invalid_response => InvalidResponse
            }};
        Err ->
            Err
    end.

-doc #{group => "Workflow commands"}.
-spec wait_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id()
) ->
    workflow_result() | no_return().
wait_workflow(Cluster, WorkflowExecutionOrId) ->
    wait_workflow(Cluster, WorkflowExecutionOrId, []).

-doc #{group => "Workflow commands"}.
-spec wait_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    Opts :: await_workflow_opts()
) ->
    workflow_result() | no_return().
wait_workflow(Cluster, WorkflowExecutionOrId, Opts) ->
    case await_workflow(Cluster, WorkflowExecutionOrId, Opts) of
        {ok, Result} -> Result;
        {error, Err} -> erlang:error(Err, [Cluster, WorkflowExecutionOrId, Opts])
    end.

-doc #{group => "Workflow commands"}.
-spec describe_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.DescribeWorkflowExecutionResponse'()}
    | response().
describe_workflow(Cluster, WorkflowExecutionOrId) ->
    describe_workflow(Cluster, WorkflowExecutionOrId, []).

-doc #{group => "Workflow commands"}.
-spec describe_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    Opts :: describe_workflow_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.DescribeWorkflowExecutionResponse'()}
    | response().
describe_workflow(Cluster, WorkflowExecutionOrId, Opts) ->
    DefaultOpts = [
        {namespace, unicode, "default"},
        %% SDK
        {grpc_opts, map, ?DEFAULT_GRPC_OPTS, merge},
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    SName = 'DescribeWorkflowExecution',
    ReqMN = 'temporal.api.workflowservice.v1.DescribeWorkflowExecutionRequest',
    RspMN = 'temporal.api.workflowservice.v1.DescribeWorkflowExecutionResponse',
    Custom = [{workflow_execution, {execution, WorkflowExecutionOrId}}],
    temporal_sdk_api_common:run_request(Cluster, Opts, DefaultOpts, SName, ReqMN, RspMN, Custom).

-doc #{group => "Workflow commands"}.
-spec get_workflow_state(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id()
) -> get_workflow_state_ret().
get_workflow_state(Cluster, WorkflowExecutionOrId) ->
    get_workflow_state(Cluster, WorkflowExecutionOrId, []).

-doc #{group => "Workflow commands"}.
-spec get_workflow_state(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    Opts :: describe_workflow_opts()
) -> get_workflow_state_ret().
get_workflow_state(Cluster, WorkflowExecutionOrId, Opts) ->
    case describe_workflow(Cluster, WorkflowExecutionOrId, Opts) of
        {ok, #{workflow_execution_info := #{status := Status}}} ->
            {ok, temporal_sdk_api_history:workflow_execution_status(Status)};
        {ok, InvalidTemporalResponse} ->
            {error, #{
                reason =>
                    "Invalid DescribeWorkflowExecutionResponse. Missing <workflow_execution_info.status> key.",
                cluster => Cluster,
                workflow_execution_or_id => WorkflowExecutionOrId,
                invalid_response => InvalidTemporalResponse
            }};
        Err ->
            % eqwalizer:ignore
            Err
    end.

-doc #{group => "Workflow commands"}.
-spec get_workflow_history(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id()
) ->
    {ok, [?TEMPORAL_SPEC:'temporal.api.history.v1.HistoryEvent'(), ...]}
    | call_response_error()
    | {error, Reason :: term()}.
get_workflow_history(Cluster, WorkflowExecutionOrId) ->
    % eqwalizer:ignore
    get_workflow_history(Cluster, WorkflowExecutionOrId, []).

%% docs:
%% if wait_new_event is set to true and grpc_opts timeout is less than 20 seconds
%% temporal server may respond with "context deadline exceeded" error.
%%
%% await_all - awaits full workflow execution history. Function will run
%% GetWorkflowExecutionHistoryRequest gRPC call until GetWorkflowExecutionHistoryResponse
%% returns empty next_page_token or timeout is reached.
%%
%% await_all_close - awaits all workflow events similarily to await_all with additional workflow
%% history closing event check. If after awaiting all events with GetWorkflowExecutionHistoryRequest
%% gRPC call workflow history is still not terminated with a workflow closing event, entire command is
%% retried until timeout is reached.
%%
%% await_close - awaits workflow close event. Function will run
%% GetWorkflowExecutionHistoryRequest gRPC call until GetWorkflowExecutionHistoryResponse
%% returns workflow closing event or timeout is reached.

-doc #{group => "Workflow commands"}.
-spec get_workflow_history(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    Opts :: get_workflow_history_opts()
) ->
    %% regular return:
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.GetWorkflowExecutionHistoryResponse'()}
    %% when await_all or await_close are set:
    | {ok, [?TEMPORAL_SPEC:'temporal.api.history.v1.HistoryEvent'(), ...]}
    %% when history_file is set:
    | {ok, [?TEMPORAL_SPEC:'temporal.api.history.v1.HistoryEvent'(), ...], Json :: iodata(),
        file:name_all()}
    %% when json is set:
    | {ok, [?TEMPORAL_SPEC:'temporal.api.history.v1.HistoryEvent'(), ...], Json :: iodata()}
    | call_response_error()
    | {error,
        Reason :: file:posix() | badarg | terminated | system_limit | timeout | map() | term()}.
get_workflow_history(Cluster, WorkflowExecutionOrId, Opts) ->
    IsRetryableFn = fun
        ({ok, _Result}, _RequestInfo, _Attempt) -> false;
        (_Error, _RequestInfo, _Attempt) -> true
    end,
    DefaultGrpcOpts = #{
        retry_policy => #{
            %% Maximum retry timeout: 12.5 seconds
            max_attempts => 15,
            backoff_coefficient => 2,
            initial_interval => 100,
            maximum_interval => 1_000,
            is_retryable => IsRetryableFn
        },
        timeout => 30_000,
        disable_telemetry => true
    },
    DefaultAAC =
        case
            proplists:get_value(await_all, Opts, false) orelse
                proplists:get_value(await_close, Opts, false)
        of
            true -> {await_all_close, boolean, '$_optional'};
            false -> {await_all_close, boolean, true}
        end,
    DefaultOpts = [
        {namespace, unicode, "default"},
        %% temporal.api.common.v1.WorkflowExecution execution = 2;
        {maximum_page_size, pos_integer, '$_optional'},
        {next_page_token, binary, '$_optional'},
        {wait_new_event, boolean, '$_optional'},
        {history_event_filter_type, atom, '$_optional'},
        %% bool skip_archival = 7;
        %% SDK
        {grpc_opts, map, DefaultGrpcOpts, merge},
        {raw_request, map, #{}},
        {timeout, [time, infinity], infinity},
        {await_all, boolean, false},
        DefaultAAC,
        {await_close, boolean, false},
        {history_file, [boolean, atom, unicode], false},
        {history_file_write_modes, list, []},
        {json, boolean, '$_optional'}
    ],
    maybe
        {ok, FullOpts} ?= temporal_sdk_utils_opts:build(DefaultOpts, Opts),
        ok ?= check_opts(get_workflow_history, FullOpts),
        TWE = temporal_sdk_api_common:transform_workflow_execution(WorkflowExecutionOrId),
        {GrpcOpts, Opts1} = maps:take(grpc_opts, FullOpts),
        {Timeout, Opts2} = maps:take(timeout, Opts1),
        {RawRequest, OptsF} = maps:take(raw_request, Opts2),
        Deadline =
            case Timeout of
                infinity -> infinity;
                _ -> erlang:system_time(millisecond) + Timeout
            end,
        LOpts1 = maps:with(
            [await_all, await_all_close, await_close, history_file, history_file_write_modes, json],
            OptsF
        ),
        LOpts = LOpts1#{workflow_execution => TWE},
        Req1 = maps:without(
            [await_all, await_all_close, await_close, history_file, history_file_write_modes, json],
            OptsF
        ),
        Req2 = Req1#{execution => TWE},
        Req3 =
            case LOpts of
                #{await_close := true} ->
                    Req2#{
                        maximum_page_size => 1,
                        wait_new_event => true,
                        history_event_filter_type => 'HISTORY_EVENT_FILTER_TYPE_CLOSE_EVENT'
                    };
                #{await_all := true} ->
                    Req2#{wait_new_event => true};
                #{await_all_close := true} ->
                    Req2#{wait_new_event => true};
                _ ->
                    Req2
            end,
        Req = maps:merge(Req3, RawRequest),
        do_get_workflow_history(Cluster, Req, GrpcOpts, LOpts, Deadline, [])
    end.

do_get_workflow_history(Cluster, Request, GrpcOpts, Opts, Deadline, HEAcc) ->
    R = temporal_sdk_api:request('GetWorkflowExecutionHistory', Cluster, Request, call, GrpcOpts),
    case erlang:system_time(millisecond) > Deadline of
        true ->
            {error, timeout};
        false ->
            case do_he(R, Opts) of
                {next_page_token, HE, NPT} ->
                    do_get_workflow_history(
                        Cluster,
                        Request#{next_page_token => NPT},
                        GrpcOpts,
                        Opts,
                        Deadline,
                        HEAcc ++ HE
                    );
                {maybe_restart, #{events := HE} = H} ->
                    case temporal_sdk_api_workflow_task:is_history_closed(H) of
                        true ->
                            fin_get_workflow_history(Opts, Cluster, R, HEAcc ++ HE, GrpcOpts);
                        _ ->
                            do_get_workflow_history(
                                Cluster,
                                maps:without([next_page_token], Request),
                                GrpcOpts,
                                Opts,
                                Deadline,
                                []
                            )
                    end;
                maybe_restart ->
                    case temporal_sdk_api_workflow_task:is_history_closed(HEAcc) of
                        true ->
                            fin_get_workflow_history(Opts, Cluster, R, HEAcc, GrpcOpts);
                        _ ->
                            do_get_workflow_history(
                                Cluster,
                                maps:without([next_page_token], Request),
                                GrpcOpts,
                                Opts,
                                Deadline,
                                []
                            )
                    end;
                {done, HE} ->
                    fin_get_workflow_history(Opts, Cluster, R, HEAcc ++ HE, GrpcOpts);
                {error, Err} ->
                    Err
            end
    end.

do_he({ok, #{next_page_token := NPT, history := #{events := [_ | _]} = H}}, #{
    await_all_close := true
}) when NPT =:= ~""; NPT =:= "" ->
    {maybe_restart, H};
do_he({ok, #{next_page_token := NPT}}, #{await_all_close := true}) when
    NPT =:= ~""; NPT =:= ""
->
    maybe_restart;
%
do_he({ok, #{next_page_token := NPT, history := #{events := HE}}}, #{}) when
    NPT =:= ~""; NPT =:= ""
->
    {done, HE};
do_he({ok, #{next_page_token := NPT}}, #{}) when
    NPT =:= ~""; NPT =:= ""
->
    {done, []};
%
do_he({ok, #{next_page_token := NPT, history := #{events := HE}}}, O) when
    map_get(await_close, O); map_get(await_all, O); map_get(await_all_close, O)
->
    {next_page_token, HE, NPT};
do_he({ok, #{next_page_token := NPT}}, O) when
    map_get(await_close, O); map_get(await_all, O); map_get(await_all_close, O)
->
    {next_page_token, [], NPT};
do_he({ok, #{history := #{events := HE}}}, #{}) ->
    {done, HE};
do_he({ok, #{}}, #{}) ->
    {done, []};
do_he(Err, #{}) ->
    {error, Err}.

fin_get_workflow_history(
    #{history_file := HF, history_file_write_modes := HFM} = Opts,
    Cluster,
    _Response,
    HistoryEvents,
    GrpcOpts
) when HF =/= false ->
    Events = #{events => HistoryEvents},
    maybe
        {ok, Json} ?=
            temporal_sdk_api:to_json('temporal.api.history.v1.History', Cluster, Events, GrpcOpts),
        {ok, Filename} ?= fname_get_workflow_history(Opts),
        ok ?= file:write_file(Filename, Json, HFM),
        {ok, HistoryEvents, Json, Filename}
    end;
fin_get_workflow_history(#{json := true}, Cluster, _Response, HE, GrpcOpts) ->
    fin_get_workflow_history_json(Cluster, HE, GrpcOpts);
fin_get_workflow_history(O, _Cluster, _Response, HistoryEvents, _GrpcOpts) when
    map_get(await_close, O); map_get(await_all, O); map_get(await_all_close, O)
->
    {ok, HistoryEvents};
fin_get_workflow_history(_Opts, _Cluster, Response, _HistoryEvents, _GrpcOpts) ->
    Response.

fin_get_workflow_history_json(Cluster, HistoryEvents, GrpcOpts) ->
    Events = #{events => HistoryEvents},
    case temporal_sdk_api:to_json('temporal.api.history.v1.History', Cluster, Events, GrpcOpts) of
        {ok, Json} -> {ok, HistoryEvents, Json};
        Err -> Err
    end.

fname_get_workflow_history(#{
    history_file := true, workflow_execution := #{run_id := RunId}
}) ->
    temporal_sdk_utils_unicode:characters_to_list([RunId, ".json"]);
fname_get_workflow_history(#{
    history_file := true, workflow_execution := #{workflow_id := WorkflowId}
}) ->
    temporal_sdk_utils_unicode:characters_to_list([do_sanitize_fname(WorkflowId), ".json"]);
fname_get_workflow_history(#{
    history_file := HTF, workflow_execution := #{run_id := RunId}
}) ->
    case filelib:is_dir(HTF) of
        false ->
            {ok, HTF};
        true ->
            case temporal_sdk_utils_unicode:characters_to_list([RunId, ".json"]) of
                {ok, FN} -> {ok, filename:join(HTF, FN)};
                Err -> Err
            end
    end;
fname_get_workflow_history(#{
    history_file := HTF, workflow_execution := #{workflow_id := WorkflowId}
}) ->
    case filelib:is_dir(HTF) of
        false ->
            {ok, HTF};
        true ->
            case
                temporal_sdk_utils_unicode:characters_to_list([
                    do_sanitize_fname(WorkflowId), ".json"
                ])
            of
                {ok, FN} -> {ok, filename:join(HTF, FN)};
                Err -> Err
            end
    end.

do_sanitize_fname(Name) -> string:replace(Name, "/", "-").

-doc #{group => "Workflow commands"}.
-spec cancel_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.RequestCancelWorkflowExecutionResponse'()}
    | response().
cancel_workflow(Cluster, WorkflowExecutionOrId) ->
    cancel_workflow(Cluster, WorkflowExecutionOrId, []).

-doc #{group => "Workflow commands"}.
-spec cancel_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    Opts :: cancel_workflow_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.RequestCancelWorkflowExecutionResponse'()}
    | response().
cancel_workflow(Cluster, WorkflowExecutionOrId, Opts) ->
    DefaultOpts = [
        {namespace, unicode, "default"},
        %% temporal.api.common.v1.WorkflowExecution execution = 2;
        {identity, unicode, '$_optional'},
        {request_id, unicode, '$_optional'},
        {first_execution_run_id, unicode, '$_optional'},
        {reason, unicode, '$_optional'},
        % repeated temporal.api.common.v1.Link links = 7;
        %% SDK
        {grpc_opts, map, ?DEFAULT_GRPC_OPTS, merge},
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    SName = 'RequestCancelWorkflowExecution',
    ReqMN = 'temporal.api.workflowservice.v1.RequestCancelWorkflowExecutionRequest',
    RspMN = 'temporal.api.workflowservice.v1.RequestCancelWorkflowExecutionResponse',
    Custom = [identity, {workflow_execution, WorkflowExecutionOrId}],
    temporal_sdk_api_common:run_request(Cluster, Opts, DefaultOpts, SName, ReqMN, RspMN, Custom).

-doc #{group => "Workflow commands"}.
-spec delete_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.DeleteWorkflowExecutionResponse'()}
    | response().
delete_workflow(Cluster, WorkflowExecutionOrId) ->
    delete_workflow(Cluster, WorkflowExecutionOrId, []).

-doc {file, "../../docs/temporal_sdk/delete_workflow-3.md"}.
-doc #{group => "Workflow commands"}.
-spec delete_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    Opts :: delete_workflow_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.DeleteWorkflowExecutionResponse'()}
    | response().
delete_workflow(Cluster, WorkflowExecutionOrId, Opts) ->
    DefaultOpts = [
        {namespace, unicode, "default"},
        %% temporal.api.common.v1.WorkflowExecution workflow_execution = 2;
        %% SDK
        {grpc_opts, map, ?DEFAULT_GRPC_OPTS, merge},
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    SName = 'DeleteWorkflowExecution',
    ReqMN = 'temporal.api.workflowservice.v1.DeleteWorkflowExecutionRequest',
    RspMN = 'temporal.api.workflowservice.v1.DeleteWorkflowExecutionResponse',
    Custom = [{workflow_execution, WorkflowExecutionOrId}, {evict, deleted}],
    temporal_sdk_api_common:run_request(Cluster, Opts, DefaultOpts, SName, ReqMN, RspMN, Custom).

-doc #{group => "Workflow commands"}.
-spec query_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    QueryType :: unicode:chardata()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.QueryWorkflowResponse'()}
    | response().
query_workflow(Cluster, WorkflowExecutionOrId, QueryType) ->
    query_workflow(Cluster, WorkflowExecutionOrId, QueryType, []).

-doc #{group => "Workflow commands"}.
-spec query_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    QueryType :: unicode:chardata(),
    Opts :: query_workflow_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.QueryWorkflowResponse'()}
    | response().
query_workflow(Cluster, WorkflowExecutionOrId, QueryType, Opts) ->
    ReqMN = 'temporal.api.workflowservice.v1.QueryWorkflowRequest',
    DefaultOpts =
        [
            {namespace, unicode, "default"},
            %% temporal.api.common.v1.WorkflowExecution execution = 2;
            %% string query_type = 1;
            {query_args, payloads, '$_optional', {ReqMN, [query, query_args]}},
            {header, mapstring_payload, '$_optional', {ReqMN, [query, header]}},
            {query_reject_condition, atom, '$_optional'},
            %% SDK
            {grpc_opts, map, ?DEFAULT_GRPC_OPTS, merge},
            {raw_request, map, #{}},
            {response_type, atom, call_formatted}
        ],
    SName = 'QueryWorkflow',
    RspMN = 'temporal.api.workflowservice.v1.QueryWorkflowResponse',
    Custom = [
        {workflow_execution, {execution, WorkflowExecutionOrId}},
        {new, {query_type, QueryType}},
        {nested, {query, [query_args, header, query_type]}}
    ],
    temporal_sdk_api_common:run_request(Cluster, Opts, DefaultOpts, SName, ReqMN, RspMN, Custom).

-doc #{group => "Workflow commands"}.
-spec reset_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ResetWorkflowExecutionResponse'()}
    | response().
reset_workflow(Cluster, WorkflowExecutionOrId) ->
    reset_workflow(Cluster, WorkflowExecutionOrId, []).

-doc #{group => "Workflow commands"}.
-spec reset_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    Opts :: reset_workflow_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.ResetWorkflowExecutionResponse'()}
    | response().
reset_workflow(Cluster, WorkflowExecutionOrId, Opts) ->
    DefaultOpts = [
        {namespace, unicode, "default"},
        %% temporal.api.common.v1.WorkflowExecution execution = 2;
        {reason, unicode, '$_optional'},
        {workflow_task_finish_event_id, pos_integer, 3},
        {request_id, unicode, '$_optional'},
        %% Deprecated. Use `options`.
        %% temporal.api.enums.v1.ResetReapplyType reset_reapply_type = 6 [deprecated = true];
        {reset_reapply_exclude_types, list, '$_optional'},
        {post_reset_operations, list, '$_optional'},
        {identity, unicode, '$_optional'},
        %% SDK
        {grpc_opts, map, ?DEFAULT_GRPC_OPTS, merge},
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    SName = 'ResetWorkflowExecution',
    ReqMN = 'temporal.api.workflowservice.v1.ResetWorkflowExecutionRequest',
    RspMN = 'temporal.api.workflowservice.v1.ResetWorkflowExecutionResponse',
    Custom = [
        identity,
        {id, request_id},
        {workflow_execution, WorkflowExecutionOrId}
    ],
    temporal_sdk_api_common:run_request(Cluster, Opts, DefaultOpts, SName, ReqMN, RspMN, Custom).

-doc #{group => "Workflow commands"}.
-spec signal_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    SignalName :: unicode:chardata()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.SignalWorkflowExecutionResponse'()}
    | response().
signal_workflow(Cluster, WorkflowExecutionOrId, SignalName) ->
    signal_workflow(Cluster, WorkflowExecutionOrId, SignalName, []).

-doc #{group => "Workflow commands"}.
-spec signal_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    SignalName :: unicode:chardata(),
    Opts :: signal_workflow_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.SignalWorkflowExecutionResponse'()}
    | response().
signal_workflow(Cluster, WorkflowExecutionOrId, SignalName, Opts) ->
    ReqMN = 'temporal.api.workflowservice.v1.SignalWorkflowExecutionRequest',
    DefaultOpts =
        [
            {namespace, unicode, "default"},
            %% temporal.api.common.v1.WorkflowExecution workflow_execution = 2;
            %% string signal_name = 3;
            {input, payloads, '$_optional', {ReqMN, input}},
            {identity, unicode, '$_optional'},
            {request_id, unicode, '$_optional'},
            {header, header, '$_optional', {ReqMN, header}},
            %% repeated temporal.api.common.v1.Link links = 10;
            %% SDK
            {grpc_opts, map, ?DEFAULT_GRPC_OPTS, merge},
            {raw_request, map, #{}},
            {response_type, atom, call_formatted}
        ],
    SName = 'SignalWorkflowExecution',
    RspMN = 'temporal.api.workflowservice.v1.SignalWorkflowExecutionResponse',
    Custom = [
        identity,
        {id, request_id},
        {workflow_execution, WorkflowExecutionOrId},
        {new, {signal_name, SignalName}}
    ],
    temporal_sdk_api_common:run_request(Cluster, Opts, DefaultOpts, SName, ReqMN, RspMN, Custom).

-doc #{group => "Workflow commands"}.
-spec terminate_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.TerminateWorkflowExecutionResponse'()}
    | response().
terminate_workflow(Cluster, WorkflowExecutionOrId) ->
    terminate_workflow(Cluster, WorkflowExecutionOrId, []).

-doc {file, "../../docs/temporal_sdk/terminate_workflow-3.md"}.
-doc #{group => "Workflow commands"}.
-spec terminate_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    Opts :: terminate_workflow_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.TerminateWorkflowExecutionResponse'()}
    | response().
terminate_workflow(Cluster, WorkflowExecutionOrId, Opts) ->
    ReqMN = 'temporal.api.workflowservice.v1.TerminateWorkflowExecutionRequest',
    DefaultOpts = [
        {namespace, unicode, "default"},
        %% temporal.api.common.v1.WorkflowExecution workflow_execution = 2;
        {reason, unicode, '$_optional'},
        {details, payloads, '$_optional', {ReqMN, details}},
        {identity, unicode, '$_optional'},
        {first_execution_run_id, unicode, '$_optional'},
        %% repeated temporal.api.common.v1.Link links = 7;
        %% SDK
        {grpc_opts, map, ?DEFAULT_GRPC_OPTS, merge},
        {raw_request, map, #{}},
        {response_type, atom, call_formatted}
    ],
    SName = 'TerminateWorkflowExecution',
    RspMN = 'temporal.api.workflowservice.v1.TerminateWorkflowExecutionResponse',
    Custom = [identity, {workflow_execution, WorkflowExecutionOrId}, {evict, terminated}],
    temporal_sdk_api_common:run_request(Cluster, Opts, DefaultOpts, SName, ReqMN, RspMN, Custom).

% TODO
% -doc #{group => "Workflow commands"}.
% -spec update_workflow(
%     Cluster :: temporal_sdk_cluster:cluster_name(),
%     WorkflowExecutionOrId :: workflow_execution_or_id(),
%     Name :: unicode:chardata(),
%     Opts :: update_workflow_opts()
% ) ->
%     {ok, ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.UpdateWorkflowExecutionResponse'()}
%     | response().
% update_workflow(Cluster, WorkflowExecutionOrId, Name, Opts) ->
%     MsgName = 'temporal.api.workflowservice.v1.UpdateWorkflowExecutionRequest',
%     DefaultOpts =
%         [
%             {namespace, unicode, "default"},
%             %% temporal.api.common.v1.WorkflowExecution execution = 2;
%             {first_execution_run_id, unicode, '$_optional'},
%             {wait_for_stage, [atom, non_neg_integer],
%                 'UPDATE_WORKFLOW_EXECUTION_LIFECYCLE_STAGE_COMPLETED'},
%             %% temporal.api.update.v1.Request request meta:
%             {update_id, unicode, '$_optional'},
%             {identity, unicode, '$_optional'},
%             %% temporal.api.update.v1.Request request input:
%             {header, mapstring_payload, '$_optional', {MsgName, [request, input, header]}},
%             %% string name = 2;
%             {args, payloads, '$_optional', {MsgName, [request, input, args]}},
%             %% SDK
%             {grpc_opts, map, ?DEFAULT_GRPC_OPTS, merge},
%             {raw_request, map, #{}},
%             {response_type, atom, call_formatted}
%         ],
%     maybe
%         {ok, ApiCtx} ?= temporal_sdk_api_context:build(Cluster),
%         {ok,
%             #{
%                 grpc_opts := GrpcOpts,
%                 raw_request := RawRequest,
%                 response_type := ResponseType,
%                 wait_for_stage := WaitForStage
%             } =
%                 FullOpts} ?=
%             temporal_sdk_utils_opts:build(DefaultOpts, Opts, ApiCtx),
%         Req0 = maps:with([namespace, first_execution_run_id], FullOpts),
%         Req1 = Req0#{
%             workflow_execution => WorkflowExecution,
%             wait_policy => #{lifecycle_stage => WaitForStage}
%         },
%         RMeta0 = maps:with([update_id], FullOpts),
%         RMeta = temporal_sdk_api:put_identity(ApiCtx, MsgName, RMeta0),
%         RInput0 = maps:with([header, args], FullOpts),
%         RInput = RInput0#{name => Name},
%         R = #{meta => RMeta, input => RInput},
%         Req = maps:merge(Req1#{request => R}, RawRequest),
%         Response = temporal_sdk_api:request(
%             'UpdateWorkflowExecution', Cluster, Req, ResponseType, GrpcOpts
%         ),
%         temporal_sdk_api_common:format_response(
%             'temporal.api.workflowservice.v1.UpdateWorkflowExecutionResponse',
%             ResponseType,
%             Response,
%             ApiCtx
%         )
%     else
%         Err -> Err
%     end.

%% -------------------------------------------------------------------------------------------------
%% Utility functions

%% For "continued-as-new" workflows only parent workflow is replayed and continuation workflow must
%% be replayed separately.

-doc #{group => "Utility functions"}.
-spec replay_json(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowMod :: module(),
    Json :: unicode:chardata()
) -> replay_json_ret().
replay_json(Cluster, WorkflowMod, Json) ->
    replay_json(Cluster, WorkflowMod, Json, [{worker_opts, ?DEFAULT_REPLAY_WORKER_OPTS}]).

-doc #{group => "Utility functions"}.
-spec replay_json(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowMod :: module(),
    Json :: unicode:chardata(),
    Opts :: replay_workflow_opts()
) -> replay_json_ret().
replay_json(Cluster, WorkflowMod, Json, Opts) ->
    maybe
        {ok, JsonBinary} ?= temporal_sdk_utils_unicode:characters_to_binary(Json),
        {ok, Pid, Timeout} ?= do_replay_workflow(Cluster, WorkflowMod, JsonBinary, Opts),
        receive
            {?TEMPORAL_SDK_REPLAY_TAG, {error, {error, Err, _StackTrace}}} ->
                case Err of
                    {error, #{reason := nondeterministic} = E} ->
                        {error, {nondeterministic, maps:without([reason], E)}};
                    #{reason := nondeterministic} = E ->
                        {error, {nondeterministic, maps:without([reason], E)}};
                    E ->
                        {error, E}
                end;
            {?TEMPORAL_SDK_REPLAY_TAG, {error, Err}} ->
                {error, Err};
            {?TEMPORAL_SDK_REPLAY_TAG, Result} ->
                {ok, Result}
        after Timeout ->
            exit(Pid, timeout),
            {error, timeout}
        end
    else
        MErr -> MErr
    end.

do_replay_workflow(Cluster, WorkflowMod, JsonBinary, Opts) ->
    WO =
        case proplists:is_defined(worker_id, Opts) of
            true -> '$_optional';
            false -> ?DEFAULT_REPLAY_WORKER_OPTS
        end,
    DefaultOpts = [
        {timeout, [infinity, non_neg_integer], infinity},
        {client_opts, map, #{}},
        {worker_id, [atom, unicode], '$_optional'},
        {worker_opts, [list, map], WO},
        {task_overwrites, list, '$_optional'}
    ],
    maybe
        {ok, #{client_opts := COO, timeout := Timeout} = O} ?=
            temporal_sdk_utils_opts:build(DefaultOpts, Opts),
        ok ?= check_opts(replay_workflow, O),
        {ok, #{client_opts := COA} = AC0} ?= temporal_sdk_api_context:build(Cluster),
        {ok, #{grpc_opts := GrpcOpts} = ClientOpts} ?=
            temporal_sdk_utils_maps:deep_merge_opts(COA, COO),
        AC1 = AC0#{client_opts := ClientOpts},
        {ok, History} ?=
            temporal_sdk_api:from_json(
                'temporal.api.history.v1.History', Cluster, JsonBinary, GrpcOpts
            ),
        % eqwalizer:ignore
        true ?= temporal_sdk_api_workflow_task:is_history_closed(History),
        % eqwalizer:ignore
        {ok, Task} ?= temporal_sdk_api_workflow_task:task_from_history(History),
        {ok, WorkerOpts} ?= w_opts_replay_wf(O, Cluster, Task),
        AC2 = AC1#{worker_opts => WorkerOpts, limiter_counters => [[], [], []]},
        {ok, WorkerOpts} ?= w_opts_replay_wf(O, Cluster, Task),
        ApiContext = temporal_sdk_scope:init_ctx(
            temporal_sdk_api_context:add_workflow_opts(AC2, Task, WorkflowMod)
        ),
        {ok, T} ?= task_overwrite(O, ApiContext, Task),
        {ok, Pid} ?= temporal_sdk_executor_workflow:start(ApiContext, T, self()),
        {ok, Pid, Timeout}
    end.

task_overwrite(#{task_overwrites := TO}, ApiContext, Task) ->
    do_task_overwrite(TO, ApiContext, Task);
task_overwrite(_Opts, _ApiContext, Task) ->
    {ok, Task}.

do_task_overwrite(
    [{input, Input} | TO], ApiContext, #{history := #{events := [E | TE]} = H} = Task
) ->
    case E of
        #{attributes := {workflow_execution_started_event_attributes, A}} ->
            I = temporal_sdk_api:map_to_payloads(
                ApiContext,
                'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes',
                input,
                Input
            ),
            EO = E#{attributes := {workflow_execution_started_event_attributes, A#{input := I}}},
            do_task_overwrite(TO, ApiContext, Task#{history := H#{events := [EO | TE]}});
        Err ->
            {error, #{
                reason =>
                    "Malformed task history event. "
                    "Expected `workflow_execution_started_event_attributes` event, received invalid.",
                invalid_event => Err
            }}
    end;
do_task_overwrite([], _ApiContext, Task) ->
    {ok, Task};
do_task_overwrite(Invalid, _ApiContext, _Task) ->
    {error, #{reason => "Invalid task_overwrites options.", invalid_opts => Invalid}}.

w_opts_replay_wf(#{worker_id := WorkerId}, Cluster, _Task) ->
    temporal_sdk_worker:options(Cluster, workflow, WorkerId);
w_opts_replay_wf(#{worker_opts := WorkerOpts} = Opts, Cluster, Task) when is_list(WorkerOpts) ->
    w_opts_replay_wf(Opts#{worker_opts := proplists:to_map(WorkerOpts)}, Cluster, Task);
w_opts_replay_wf(#{worker_opts := WorkerOpts}, Cluster, #{
    workflow_execution_task_queue := #{name := TQ},
    workflow_execution := #{workflow_id := WId}
}) when is_map(WorkerOpts) ->
    WO1 =
        case WorkerOpts of
            #{worker_id := _} -> WorkerOpts;
            #{} -> WorkerOpts#{worker_id => WId}
        end,
    WO2 =
        case WO1 of
            #{task_queue := _} -> WO1;
            #{} -> WO1#{task_queue => TQ}
        end,
    temporal_sdk_worker_opts:setup_replay(Cluster, WO2);
w_opts_replay_wf(_Opts, _Cluster, Task) ->
    {error, #{reason => "Incomplete task data.", incomplete_task => Task}}.

-doc #{group => "Utility functions"}.
-spec replay_file(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowMod :: module(),
    Filename :: file:name_all()
) ->
    replay_json_ret()
    | {error, Reason :: file:posix() | badarg | terminated | system_limit}.
replay_file(Cluster, WorkflowMod, Filename) ->
    replay_file(Cluster, WorkflowMod, Filename, [{worker_opts, ?DEFAULT_REPLAY_WORKER_OPTS}]).

-doc #{group => "Utility functions"}.
-spec replay_file(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowMod :: module(),
    Filename :: file:name_all(),
    Opts :: replay_workflow_opts()
) ->
    replay_json_ret()
    | {error, Reason :: file:posix() | badarg | terminated | system_limit}.
replay_file(Cluster, WorkflowMod, Filename, Opts) ->
    case file:read_file(Filename, [raw]) of
        {ok, JsonBinary} -> replay_json(Cluster, WorkflowMod, JsonBinary, Opts);
        Err -> Err
    end.

-doc #{group => "Utility functions"}.
-spec replay_task(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    TaskQueue :: unicode:chardata(),
    WorkflowType :: atom() | unicode:chardata(),
    WorkflowMod :: module()
) -> replay_json_ret() | call_response_error().
replay_task(Cluster, TaskQueue, WorkflowType, WorkflowMod) ->
    % eqwalizer:ignore
    replay_task(Cluster, TaskQueue, WorkflowType, WorkflowMod, []).

-doc #{group => "Utility functions"}.
-spec replay_task(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    TaskQueue :: unicode:chardata(),
    WorkflowType :: atom() | unicode:chardata(),
    WorkflowMod :: module(),
    Opts :: replay_task_opts()
) ->
    replay_json_ret()
    %% when history_file is set:
    | {ok, replay_workflow_ret(), file:name_all()}
    | call_response_error().
replay_task(Cluster, TaskQueue, WorkflowType, WorkflowMod, Opts) ->
    DefaultOpts = [
        {start_workflow_opts, list, [await]},
        {replay_workflow_opts, list, [{worker_opts, ?DEFAULT_REPLAY_WORKER_OPTS}]},
        {history_file, [boolean, atom, unicode], false},
        {history_file_write_modes, list, []}
    ],
    maybe
        {ok, #{start_workflow_opts := SOpts, replay_workflow_opts := ROpts} = FOpts} ?=
            temporal_sdk_utils_opts:build(DefaultOpts, Opts),
        SO =
            case proplists:is_defined(await, SOpts) of
                true -> SOpts;
                false -> [await | SOpts]
            end,
        {ok, #{workflow_execution := WE}, {State, _Attributes}} ?=
            start_workflow(Cluster, TaskQueue, WorkflowType, SO),
        NS = proplists:get_value(namespace, SO, "default"),
        GOpts =
            [await_all_close, json, {namespace, NS}] ++
                proplists:from_map(maps:with([history_file, history_file_write_modes], FOpts)),
        H = get_workflow_history(Cluster, WE, GOpts),
        fin_replay_task(H, Cluster, WorkflowMod, ROpts, State)
    else
        MErr -> MErr
    end.

fin_replay_task({ok, _Events, Json}, Cluster, WorkflowMod, ROpts, State) ->
    case replay_json(Cluster, WorkflowMod, Json, ROpts) of
        {ok, {State, _}} = R ->
            R;
        {ok, {_InvalidState, _}} = R ->
            {error, #{
                reason => "Start workflow and replay workflow states do not match.",
                replay_return => R,
                expected_state => State
            }};
        Err ->
            Err
    end;
fin_replay_task({ok, _Events, Json, File}, Cluster, WorkflowMod, ROpts, State) ->
    case replay_json(Cluster, WorkflowMod, Json, ROpts) of
        {ok, {State, _} = R} ->
            {ok, R, File};
        {ok, {_InvalidState, _}} = R ->
            {error, #{
                reason => "Start workflow and replay workflow states do not match.",
                replay_return => R,
                expected_state => State
            }}
    end;
fin_replay_task(Err, _Cluster, _WorkflowMod, _ROpts, _State) ->
    Err.

-doc #{group => "Utility functions"}.
format_response(Cluster, MessageName, Response) ->
    case temporal_sdk_api_context:build(Cluster) of
        {ok, ApiCtx} ->
            temporal_sdk_api_common:format_response(MessageName, call_formatted, Response, ApiCtx);
        Err ->
            Err
    end.

-doc #{group => "Utility functions"}.
-spec evict_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id()
) -> ok | temporal_sdk_client:call_result_error().
evict_workflow(Cluster, WorkflowExecutionOrId) ->
    evict_workflow(Cluster, WorkflowExecutionOrId, []).

-doc {file, "../../docs/temporal_sdk/evict_workflow-3.md"}.
-doc #{group => "Utility functions"}.
-spec evict_workflow(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkflowExecutionOrId :: workflow_execution_or_id(),
    Opts :: evict_workflow_opts()
) -> ok | temporal_sdk_client:call_result_error().
evict_workflow(Cluster, WorkflowExecutionOrId, Opts) ->
    DefaultOpts = [
        {namespace, unicode, "default"},
        %% SDK
        {reason, atom, evicted}
    ],
    maybe
        {ok, ApiCtx} ?= temporal_sdk_api_context:build(Cluster),
        {ok, #{namespace := Namespace, reason := Reason} = O} ?=
            temporal_sdk_utils_opts:build(DefaultOpts, Opts, ApiCtx),
        {ok, #{workflow_id := WorkflowId, run_id := RunId}} ?=
            temporal_sdk_api_common:put_run_id(Cluster, WorkflowExecutionOrId, O),
        AC = ApiCtx#{
            worker_opts => #{namespace => Namespace, task_queue => "undefined"},
            task_opts => #{
                workflow_id => WorkflowId,
                run_id => RunId,
                token => undefined,
                workflow_type => "undefined"
            }
        },
        Pids = temporal_sdk_scope:get_members(temporal_sdk_scope:init_ctx(AC)),
        [P ! {?MSG_PRV, external_evict, Reason} || P <- Pids],
        ok
    else
        Err -> Err
    end.

%% -------------------------------------------------------------------------------------------------
%% private

check_opts(replay_workflow, Opts) ->
    case Opts of
        #{worker_id := _, worker_opts := _} ->
            {error, "worker_id and worker_opts are mutually exclusive."};
        #{worker_id := _} ->
            ok;
        #{worker_opts := _} ->
            ok;
        #{} ->
            {error, "Required one of worker_id or worker_opts."}
    end;
check_opts(start_workflow, Opts) ->
    case Opts of
        #{await := _, wait := _} ->
            {error, "await and wait are mutually exclusive."};
        #{signal_input := _} = O when not is_map_key(signal_name, O) ->
            {error, "signal_input requires signal_name."};
        #{request_eager_execution := false} ->
            ok;
        #{request_eager_execution := _, signal_name := _} ->
            {error, "request_eager_execution and signal_name are mutually exclusive."};
        #{request_eager_execution := _, signal_input := _} ->
            {error, "request_eager_execution and signal_input are mutually exclusive."};
        #{request_eager_execution := true, eager_worker_id := _} ->
            ok;
        #{request_eager_execution := auto, eager_worker_id := _} ->
            ok;
        #{request_eager_execution := _, eager_worker_id := _} ->
            {error, "request_eager_execution set to invalid value."};
        #{request_eager_execution := _} ->
            {error, "request_eager_execution requires eager_worker_id."};
        #{} ->
            ok
    end;
check_opts(get_workflow_history, Opts) ->
    case Opts of
        #{history_file := true, json := true} ->
            {error, "history_file and json are mutually exclusive."};
        #{history_file := true, await_all := false} ->
            {error, "history_file requires await_all set true."};
        #{await_all := true, await_all_close := true} ->
            {error, "await_all and await_all_close are mutually exclusive."};
        #{await_all := true, await_close := true} ->
            {error, "await_all and await_close are mutually exclusive."};
        #{await_close := true, await_all_close := true} ->
            {error, "await_close and await_all_close are mutually exclusive."};
        #{await_all := true, next_page_token := _} ->
            {error, "await_all and next_page_token are mutually exclusive."};
        #{await_all := true, wait_new_event := _} ->
            {error, "await_all and wait_new_event are mutually exclusive."};
        #{await_close := true, next_page_token := _} ->
            {error, "await_close and next_page_token are mutually exclusive."};
        #{await_close := true, wait_new_event := _} ->
            {error, "await_close and wait_new_event are mutually exclusive."};
        #{await_close := true, maximum_page_size := _} ->
            {error, "await_close and maximum_page_size are mutually exclusive."};
        #{await_close := true, history_event_filter_type := _} ->
            {error, "await_close and history_event_filter_type are mutually exclusive."};
        _ ->
            ok
    end.
