-module(temporal_sdk_cluster).

% elp:ignore W0012 W0040
-moduledoc {file, "../../docs/cluster/cluster/-module.md"}.

-export([
    is_alive/1,
    list/0,
    stats/1
]).
-export([
    setup/2,
    get_counters/1
]).

-type cluster_config() :: [
    {cluster, opts() | user_opts()}
    | {client, temporal_sdk_client:opts() | temporal_sdk_client:user_opts()}
    | {activities, [temporal_sdk_worker:opts() | temporal_sdk_worker:user_opts()]}
    | {workflows, [temporal_sdk_worker:opts() | temporal_sdk_worker:user_opts()]}
    | {nexuses, [temporal_sdk_worker:opts() | temporal_sdk_worker:user_opts()]}
].
-export_type([cluster_config/0]).

-type opts() :: #{
    limiter_time_windows =>
        temporal_sdk_node:limiter_time_windows() | temporal_sdk_node:user_limiter_time_windows(),
    enable_single_distributed_workflow_execution => boolean() | undefined,
    workflow_scope => cluster_name(),
    telemetry_poll_interval => temporal_sdk:time()
}.
-export_type([opts/0]).

-type user_opts() :: [
    {limiter_time_windows,
        temporal_sdk_node:limiter_time_windows() | temporal_sdk_node:user_limiter_time_windows()}
    | {enable_single_distributed_workflow_execution, boolean() | undefined}
    | {workflow_scope, cluster_name()}
    | {telemetry_poll_interval, temporal_sdk:time()}
].
-export_type([user_opts/0]).

-type cluster_name() :: atom().
-export_type([cluster_name/0]).

-define(DEFAULT_LIMITER_TIME_WINDOW, 60_000).

-spec is_alive(Cluster :: cluster_name()) -> true | {error, invalid_cluster}.
is_alive(Cluster) ->
    case erlang:whereis(temporal_sdk_cluster_sup:local_name(Cluster)) of
        undefined -> {error, invalid_cluster};
        _ -> true
    end.

-spec list() -> [cluster_name()].
list() ->
    Fn = fun
        ({{temporal_sdk_cluster_sup, Cluster}, _Pid, supervisor, [temporal_sdk_cluster_sup]}) ->
            {true, Cluster};
        (_) ->
            false
    end,
    lists:filtermap(Fn, supervisor:which_children(temporal_sdk_sup)).

-spec stats(Cluster :: cluster_name()) ->
    {ok, temporal_sdk_limiter:stats()} | {error, invalid_cluster}.
stats(Cluster) ->
    case get_counters(Cluster) of
        {ok, C} -> {ok, temporal_sdk_limiter:get_concurrency(C)};
        Err -> Err
    end.

-doc false.
-spec setup(Cluster :: cluster_name(), Opts :: opts() | user_opts()) ->
    {ok, LimiterCounter :: temporal_sdk_limiter:counter(),
        LimiterChildSpecs :: [supervisor:child_spec()], ClusterOpts :: opts()}
    | {error, {invalid_opts, map()}}.
setup(Cluster, UserOpts) ->
    case temporal_sdk_utils_opts:build(defaults(user_opts, Cluster), UserOpts) of
        {ok, Opts} ->
            #{limiter_time_windows := TimeWindows} = Opts,
            {LCounters, LChiSpec} = temporal_sdk_limiter:setup({Cluster}, TimeWindows),
            persist_counters(Cluster, LCounters),
            {ok, LCounters, [LChiSpec], Opts};
        Err ->
            Err
    end.

defaults(user_opts, Cluster) ->
    [
        {limiter_time_windows, nested, defaults(limiter_time_windows, Cluster)},
        {enable_single_distributed_workflow_execution, boolean, true},
        {telemetry_poll_interval, time, 10_000},
        {workflow_scope, atom, Cluster}
    ];
defaults(limiter_time_windows, _Cluster) ->
    [
        {activity_direct, time, ?DEFAULT_LIMITER_TIME_WINDOW},
        {activity_eager, time, ?DEFAULT_LIMITER_TIME_WINDOW},
        {activity_regular, time, ?DEFAULT_LIMITER_TIME_WINDOW},
        {activity_session, time, ?DEFAULT_LIMITER_TIME_WINDOW},
        {nexus, time, ?DEFAULT_LIMITER_TIME_WINDOW},
        {workflow, time, ?DEFAULT_LIMITER_TIME_WINDOW}
    ].

persist_counters(Cluster, Counters) -> persistent_term:put({?MODULE, counters, Cluster}, Counters).

-doc false.
-spec get_counters(Cluster :: cluster_name()) ->
    {ok, temporal_sdk_limiter:counter()} | {error, invalid_cluster}.
get_counters(Cluster) ->
    case persistent_term:get({?MODULE, counters, Cluster}, '$_undefined') of
        '$_undefined' -> {error, invalid_cluster};
        V -> {ok, V}
    end.
