-module(temporal_sdk_worker_manager_sup).
-behaviour(supervisor).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    start_config_workers/0,
    start_worker/4,
    terminate_worker/3
]).
-export([
    start_link/2
]).
-export([
    init/1
]).

-spec start_link(
    ApiContext :: temporal_sdk_api:context(),
    LimiterCounters :: temporal_sdk_limiter:counters()
) -> supervisor:startlink_ret().
start_link(ApiContext, LimiterCounters) ->
    #{cluster := Cluster, worker_type := WorkerType} = ApiContext,
    supervisor:start_link({local, supervisor_ref(Cluster, WorkerType)}, ?MODULE, [
        ApiContext, LimiterCounters
    ]).

init([ApiContext, LimiterCounters]) ->
    #{cluster := Cluster, worker_type := WorkerType} = ApiContext,
    ChildSpecs = [
        #{
            id => {temporal_sdk_worker_sup, Cluster, WorkerType},
            start => {temporal_sdk_worker_sup, start_link, [ApiContext, LimiterCounters]},
            type => supervisor,
            restart => transient
        }
    ],
    {ok, {#{strategy => simple_one_for_one}, ChildSpecs}}.

-spec start_worker(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: activity | nexus | workflow,
    WorkerOpts :: temporal_sdk_worker:user_opts() | temporal_sdk_worker:opts(),
    LogError :: boolean()
) ->
    {ok, temporal_sdk_worker:opts()}
    | {invalid_opts, map()}
    | temporal_sdk_worker:invalid_error()
    | {error, supervisor:startchild_err()}.
start_worker(Cluster, WorkerType, WorkerOpts, LogError) ->
    maybe
        true ?= temporal_sdk_cluster:is_alive(Cluster),
        {ok, LCounters, LChiSpec, Opts} ?=
            temporal_sdk_worker_opts:setup(Cluster, WorkerType, WorkerOpts),
        ok ?= start_child(supervisor_ref(Cluster, WorkerType), [LCounters, LChiSpec, Opts]),
        {ok, Opts}
    else
        Err ->
            case LogError of
                false ->
                    Err;
                true ->
                    temporal_sdk_utils_logger:log_error(
                        Err,
                        ?MODULE,
                        ?FUNCTION_NAME,
                        "Error starting Temporal SDK worker. "
                        "Check worker configuration.",
                        #{cluster => Cluster, worker_type => WorkerType, user_opts => WorkerOpts}
                    )
            end
    end.

start_child(SupRef, ExtraArgs) ->
    case supervisor:start_child(SupRef, ExtraArgs) of
        {ok, _Pid} -> ok;
        {ok, _Pid, _Info} -> ok;
        Err -> Err
    end.

-spec terminate_worker(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: activity | nexus | workflow,
    WorkerId :: temporal_sdk_worker:worker_id()
) -> ok | {error, invalid_cluster | not_found | simple_one_for_one}.
terminate_worker(Cluster, WorkerType, WorkerId) ->
    case temporal_sdk_cluster:is_alive(Cluster) of
        true ->
            case temporal_sdk_worker_registry:whereis_name({Cluster, WorkerType, WorkerId}) of
                undefined ->
                    {error, not_found};
                Pid ->
                    temporal_sdk_telemetry:execute([worker, terminate], #{
                        cluster => Cluster, worker_type => WorkerType, worker_id => WorkerId
                    }),
                    supervisor:terminate_child(supervisor_ref(Cluster, WorkerType), Pid)
            end;
        Err ->
            Err
    end.

-spec start_config_workers() -> ok.
start_config_workers() ->
    case application:get_env(temporal_sdk, clusters) of
        {ok, Clusters} -> do_start_config_workers(Clusters);
        _ -> ok
    end.

do_start_config_workers([{Cluster, Config} | TClusters]) ->
    start_config_worker(proplists:get_value(activities, Config), activity, Cluster),
    start_config_worker(proplists:get_value(nexuses, Config), nexus, Cluster),
    start_config_worker(proplists:get_value(workflows, Config), workflow, Cluster),
    do_start_config_workers(TClusters);
do_start_config_workers([]) ->
    ok.

start_config_worker(undefined, _WorkerType, _Cluster) ->
    ok;
start_config_worker([WorkerConfig | TWorkerConfigs], WorkerType, Cluster) ->
    start_worker(Cluster, WorkerType, WorkerConfig, true),
    start_config_worker(TWorkerConfigs, WorkerType, Cluster);
start_config_worker([], _WorkerType, _Cluster) ->
    ok.

supervisor_ref(Cluster, WorkerType) ->
    temporal_sdk_utils_path:atom_path([?MODULE, Cluster, WorkerType]).
