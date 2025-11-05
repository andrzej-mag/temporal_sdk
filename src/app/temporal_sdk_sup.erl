-module(temporal_sdk_sup).
-behaviour(supervisor).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    start_link/0
]).
-export([
    init/1
]).

-define(DEFAULT_WORKFLOW_SCOPE_PARTITIONS_SIZE, 10).

-spec start_link() -> supervisor:startlink_ret().
start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

-spec init([]) ->
    {ok, {SupFlags :: supervisor:sup_flags(), [ChildSpec :: supervisor:child_spec()]}} | ignore.
init([]) ->
    EnvNodeOpts = application:get_env(temporal_sdk, node, []),
    EnvClustersConfig = application:get_env(temporal_sdk, clusters, []),
    case temporal_sdk_node:setup(node, EnvNodeOpts) of
        {ok, LimiterCounters, LimiterChiSpecs, NodeOpts} ->
            temporal_sdk_telemetry:setup(NodeOpts),
            temporal_sdk_telemetry:execute([node, init], #{opts => NodeOpts}),
            {ScopeList, ScopeConfig} = scopes(NodeOpts, EnvClustersConfig),
            #{enable_single_distributed_workflow_execution := SDWE} = NodeOpts,
            ChildSpecs =
                clusters_specs(EnvClustersConfig, LimiterCounters, ScopeConfig, SDWE) ++
                    scope_specs(ScopeList) ++ telemetry_poller_specs(NodeOpts) ++ LimiterChiSpecs,
            {ok, {#{strategy => one_for_one}, ChildSpecs}};
        Err ->
            temporal_sdk_utils_logger:log_error(
                "Invalid Temporal SDK configuration.",
                ?MODULE,
                ?FUNCTION_NAME,
                "Error initializing Temporal SDK. "
                "Check SDK node configuration. "
                "SDK cluster(s) not started.",
                Err
            ),
            {ok, {#{strategy => one_for_one}, []}}
    end.

clusters_specs(Clusters, LimiterCounters, ScopeConfig, EnableSingleDistributedWorkflowExecution) ->
    [
        #{
            id => {temporal_sdk_cluster_sup, Cluster},
            start =>
                {temporal_sdk_cluster_sup, start_link, [
                    #{
                        cluster => Cluster,
                        enable_single_distributed_workflow_execution =>
                            EnableSingleDistributedWorkflowExecution,
                        workflow_scope => proplists:get_value(Cluster, ScopeConfig)
                    },
                    ClusterConfig,
                    LimiterCounters
                ]},
            type => supervisor
        }
     || {Cluster, ClusterConfig} <- Clusters
    ].

scope_specs(ScopeList) ->
    [
        #{
            id => temporal_sdk_scope_sup,
            start => {temporal_sdk_scope_sup, start_link, [ScopeList]},
            type => supervisor
        }
    ].

scopes(NodeOpts, EnvClustersConfig) ->
    Partitions = map_get(workflow_scope_partitions_size, NodeOpts),
    Scopes = lists:uniq(
        lists:map(
            fun({ClusterName, ClusterOpts}) when is_list(ClusterOpts) ->
                default_scope(proplists:get_value(cluster, ClusterOpts, #{}), ClusterName)
            end,
            EnvClustersConfig
        )
    ),
    ScopeList = lists:map(
        fun(Scope) ->
            {Scope, proplists:get_value(Scope, Partitions, ?DEFAULT_WORKFLOW_SCOPE_PARTITIONS_SIZE)}
        end,
        Scopes
    ),
    ScopeConfig =
        lists:map(
            fun({ClusterName, ClusterOpts}) when is_list(ClusterOpts) ->
                Scope = default_scope(proplists:get_value(cluster, ClusterOpts, #{}), ClusterName),
                {ClusterName, {Scope, proplists:get_value(Scope, ScopeList)}}
            end,
            EnvClustersConfig
        ),
    {ScopeList, ScopeConfig}.

default_scope(#{workflow_scope := S}, _ClusterName) ->
    S;
default_scope(#{}, ClusterName) ->
    ClusterName;
default_scope(Opts, ClusterName) when is_list(Opts) ->
    proplists:get_value(workflow_scope, Opts, ClusterName).

telemetry_poller_specs(#{telemetry_poll_interval := Interval}) ->
    [
        #{
            id => {temporal_sdk_telemetry_poller, node},
            start =>
                {temporal_sdk_telemetry_poller, start_link, [
                    node, Interval, temporal_sdk_node_telemetry_poller, #{}
                ]}
        }
    ].
