-module(temporal_sdk_cluster_sup).
-behaviour(supervisor).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    get_context/1
]).
-export([
    start_link/3,
    init/1,
    local_name/1
]).

-spec start_link(
    ApiContext :: temporal_sdk_api:context(),
    ClusterConfig :: temporal_sdk_cluster:cluster_config(),
    LimiterCounters :: temporal_sdk_limiter:counters()
) -> supervisor:startlink_ret().
start_link(#{cluster := Cluster} = ApiContext, ClusterConfig, LimiterCounters) ->
    supervisor:start_link({local, local_name(Cluster)}, ?MODULE, [
        ApiContext, ClusterConfig, LimiterCounters
    ]).

init([#{cluster := Cluster} = ApiContext, ClusterConfig, LimiterCounters]) ->
    EnvClustOpts = proplists:get_value(cluster, ClusterConfig, []),
    EnvClientOpts = proplists:get_value(client, ClusterConfig, []),
    maybe
        {ok, LCounters, LChiSpec, ClusterOpts} ?= temporal_sdk_cluster:setup(Cluster, EnvClustOpts),
        {ok, ClientOpts} ?= temporal_sdk_client_opts:init_opts(Cluster, EnvClientOpts),
        #{telemetry_poll_interval := TelemetryPollInterval} = ClusterOpts,
        temporal_sdk_telemetry:execute([cluster, init], #{cluster => Cluster, opts => ClusterOpts}),
        ApiContext1 = update_enable_single_distributed_workflow_execution(ApiContext, ClusterOpts),
        ApiContext2 = ApiContext1#{client_opts => ClientOpts},
        persist_context(Cluster, ApiContext2),
        ChildSpecs =
            child_specs(ApiContext2, TelemetryPollInterval, LimiterCounters#{cluster => LCounters}) ++
                LChiSpec,
        {ok, {#{strategy => one_for_one}, ChildSpecs}}
    else
        Err ->
            temporal_sdk_utils_logger:log_error(
                "Invalid Temporal SDK configuration.",
                ?MODULE,
                ?FUNCTION_NAME,
                "Error starting cluster supervisor. "
                "Check SDK clusters configuration. "
                "SDK cluster not started.",
                Err
            ),
            {ok, {#{strategy => one_for_one}, []}}
    end.

persist_context(Cluster, ApiContext) ->
    persistent_term:put({?MODULE, context, Cluster}, ApiContext).

-spec get_context(Cluster :: temporal_sdk_cluster:cluster_name()) ->
    {ok, ApiContext :: temporal_sdk_api:context()} | {error, invalid_cluster}.
get_context(Cluster) ->
    case persistent_term:get({?MODULE, context, Cluster}, '$_undefined') of
        '$_undefined' -> {error, invalid_cluster};
        V -> {ok, V}
    end.

update_enable_single_distributed_workflow_execution(
    #{enable_single_distributed_workflow_execution := _} = ApiContext,
    #{enable_single_distributed_workflow_execution := V}
) when is_boolean(V) ->
    ApiContext#{enable_single_distributed_workflow_execution := V};
update_enable_single_distributed_workflow_execution(
    #{enable_single_distributed_workflow_execution := V} = ApiContext,
    #{enable_single_distributed_workflow_execution := undefined}
) when is_boolean(V) ->
    ApiContext.

child_specs(ApiContext, TelemetryPollInterval, Limiters) ->
    #{cluster := Cluster, client_opts := ClientOpts} = ApiContext,
    [
        #{
            id => {temporal_sdk_client_sup, Cluster},
            start => {temporal_sdk_client_sup, start_link, [Cluster, ClientOpts]},
            type => supervisor
        },
        #{
            id => {temporal_sdk_telemetry_poller, Cluster},
            start =>
                {temporal_sdk_telemetry_poller, start_link, [
                    Cluster,
                    TelemetryPollInterval,
                    temporal_sdk_cluster_telemetry_poller,
                    #{cluster => Cluster}
                ]}
        },
        #{
            id => {temporal_sdk_worker_registry, Cluster, activity},
            start => {temporal_sdk_worker_registry, start_link, [Cluster, activity]},
            type => supervisor
        },
        #{
            id => {temporal_sdk_worker_registry, Cluster, activity_opts},
            start => {temporal_sdk_worker_registry, start_link, [Cluster, activity_opts]},
            type => supervisor
        },
        #{
            id => {temporal_sdk_worker_registry, Cluster, nexus},
            start => {temporal_sdk_worker_registry, start_link, [Cluster, nexus]},
            type => supervisor
        },
        #{
            id => {temporal_sdk_worker_registry, Cluster, nexus_opts},
            start => {temporal_sdk_worker_registry, start_link, [Cluster, nexus_opts]},
            type => supervisor
        },
        #{
            id => {temporal_sdk_worker_registry, Cluster, workflow},
            start => {temporal_sdk_worker_registry, start_link, [Cluster, workflow]},
            type => supervisor
        },
        #{
            id => {temporal_sdk_worker_registry, Cluster, workflow_opts},
            start => {temporal_sdk_worker_registry, start_link, [Cluster, workflow_opts]},
            type => supervisor
        },
        #{
            id => {temporal_sdk_worker_manager_sup, Cluster, activity},
            start =>
                {temporal_sdk_worker_manager_sup, start_link, [
                    ApiContext#{
                        worker_type => activity,
                        enable_single_distributed_workflow_execution := undefined,
                        workflow_scope := undefined
                    },
                    Limiters
                ]},
            type => supervisor
        },
        #{
            id => {temporal_sdk_worker_manager_sup, Cluster, nexus},
            start =>
                {temporal_sdk_worker_manager_sup, start_link, [
                    ApiContext#{
                        worker_type => nexus,
                        enable_single_distributed_workflow_execution := undefined,
                        workflow_scope := undefined
                    },
                    Limiters
                ]},
            type => supervisor
        },
        #{
            id => {temporal_sdk_worker_manager_sup, Cluster, workflow},
            start =>
                {temporal_sdk_worker_manager_sup, start_link, [
                    ApiContext#{
                        worker_type => workflow
                    },
                    Limiters
                ]},
            type => supervisor
        }
    ].

local_name(Cluster) -> temporal_sdk_utils_path:atom_path([?MODULE, Cluster]).
