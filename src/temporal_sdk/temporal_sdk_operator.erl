-module(temporal_sdk_operator).

% elp:ignore W0012 W0040
-moduledoc {file, "../../docs/temporal_sdk/operator/-module.md"}.

-export([
    create_nexus_endpoint/3,

    add_or_update_remote_cluster/2,
    remove_remote_cluster/2,
    list_clusters/2
]).

-include("proto.hrl").

-type create_nexus_endpoint_opts() :: [
    {name, unicode:chardata()}
    | {description, temporal_sdk:term_to_payload()}
    | {worker_target_namespace, unicode:chardata()}
    | {worker_target_task_queue, unicode:chardata()}
    | {external_target_url, unicode:chardata()}
].

-spec create_nexus_endpoint(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Name :: unicode:chardata(),
    Opts :: create_nexus_endpoint_opts()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.nexus.v1.Endpoint'()} | temporal_sdk:call_response_error().
create_nexus_endpoint(Cluster, Name, Opts) ->
    DefaultOpts = [
        {description, any, '$_optional'},
        {worker_target_namespace, unicode, "default"},
        {worker_target_task_queue, unicode, '$_optional'},
        {external_target_url, unicode, '$_optional'}
    ],
    maybe
        {ok, ApiCtx} ?= temporal_sdk_api_context:build(Cluster),
        {ok, O} ?= temporal_sdk_utils_opts:build(DefaultOpts, Opts),
        ok ?= check_opts(create_nexus_endpoint, O),
        Req1 = #{name => Name},
        Req2 =
            case O of
                #{description := D} -> Req1#{description => D};
                #{} -> Req1
            end,
        Req3 =
            case O of
                #{worker_target_namespace := NS, worker_target_task_queue := TQ} ->
                    Req2#{target => #{variant => {worker, #{namespace => NS, task_queue => TQ}}}};
                #{} ->
                    Req2
            end,
        Req4 =
            case O of
                #{external_target_url := U} ->
                    Req2#{target => #{variant => {external, #{url => U}}}};
                #{} ->
                    Req3
            end,
        Req = #{spec => Req4},
        {ok, #{endpoint := E}} ?=
            temporal_sdk_api:request('CreateNexusEndpoint', ApiCtx, Req, call),
        {ok, E}
    else
        Err -> Err
    end.

-spec add_or_update_remote_cluster(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Request :: ?TEMPORAL_SPEC_OPERATOR:'temporal.api.operatorservice.v1.AddOrUpdateRemoteClusterRequest'()
) ->
    {ok,
        ?TEMPORAL_SPEC_OPERATOR:'temporal.api.operatorservice.v1.AddOrUpdateRemoteClusterResponse'()}
    | temporal_sdk_client:call_result_error().
add_or_update_remote_cluster(Cluster, Request) ->
    temporal_sdk_api:request('AddOrUpdateRemoteCluster', Cluster, Request).

-spec remove_remote_cluster(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Request :: ?TEMPORAL_SPEC_OPERATOR:'temporal.api.operatorservice.v1.RemoveRemoteClusterRequest'()
) ->
    {ok, ?TEMPORAL_SPEC_OPERATOR:'temporal.api.operatorservice.v1.RemoveRemoteClusterResponse'()}
    | temporal_sdk_client:call_result_error().
remove_remote_cluster(Cluster, Request) ->
    temporal_sdk_api:request('RemoveRemoteCluster', Cluster, Request).

-spec list_clusters(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Request :: ?TEMPORAL_SPEC_OPERATOR:'temporal.api.operatorservice.v1.ListClustersRequest'()
) ->
    {ok, ?TEMPORAL_SPEC_OPERATOR:'temporal.api.operatorservice.v1.ListClustersResponse'()}
    | temporal_sdk_client:call_result_error().
list_clusters(Cluster, Request) ->
    temporal_sdk_api:request('ListClusters', Cluster, Request).

%% -------------------------------------------------------------------------------------------------
%% private

check_opts(create_nexus_endpoint, Opts) ->
    case Opts of
        #{worker_target_namespace := _, external_target_url := _} ->
            {invalid_opts, "worker_target and external_target are mutually exclusive"};
        #{worker_target_task_queue := _, external_target_url := _} ->
            {invalid_opts, "worker_target and external_target are mutually exclusive"};
        #{worker_target_namespace := _, worker_target_task_queue := _} ->
            ok;
        #{worker_target_namespace := _} ->
            {invalid_opts, "worker_target requires worker_target_task_queue."};
        _ ->
            ok
    end.
