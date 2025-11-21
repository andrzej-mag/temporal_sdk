-module(temporal_sdk_node).

% elp:ignore W0012 W0040 E1599
-moduledoc {file, "../../docs/node/-module.md"}.

-export([
    stats/0,
    os_stats/0,
    os_disk_mounts/0
]).
-export([
    setup/2,
    get_counters/1
]).

-type sdk_config() :: [
    {node, NodeOpts :: opts() | user_opts()}
    | {clusters, [
        {
            ClusterName :: temporal_sdk_cluster:cluster_name(),
            ClusterConfig :: temporal_sdk_cluster:cluster_config()
        }
    ]}
].
-export_type([sdk_config/0]).

-type opts() :: #{
    limiter_time_windows => limiter_time_windows() | user_limiter_time_windows(),
    workflow_scope_partitions_size => [scope_config()],
    enable_single_distributed_workflow_execution => boolean(),
    telemetry_poll_interval => temporal_sdk:time(),
    telemetry_logs => temporal_sdk_telemetry_logs:opts(),
    telemetry_metrics => [atom()],
    telemetry_traces => [atom()]
}.
-export_type([opts/0]).

-type scope_config() :: {
    Scope :: temporal_sdk_cluster:cluster_name(), PartitionsSize :: pos_integer()
}.
-export_type([scope_config/0]).

-type user_opts() :: [
    {limiter_time_windows, limiter_time_windows() | user_limiter_time_windows()}
    | {workflow_scope_partitions_size, [scope_config()]}
    | {enable_single_distributed_workflow_execution, boolean()}
    | enable_single_distributed_workflow_execution
    | {telemetry_poll_interval, temporal_sdk:time()}
    | {telemetry_logs, temporal_sdk_telemetry_logs:opts()}
    | {telemetry_metrics, [atom()]}
    | {telemetry_traces, [atom()]}
].
-export_type([user_opts/0]).

-type limiter_time_windows() :: #{
    activity_direct => temporal_sdk_limiter:time_window(),
    activity_eager => temporal_sdk_limiter:time_window(),
    activity_regular => temporal_sdk_limiter:time_window(),
    activity_session => temporal_sdk_limiter:time_window(),
    nexus => temporal_sdk_limiter:time_window(),
    workflow => temporal_sdk_limiter:time_window()
}.
-export_type([limiter_time_windows/0]).

-type user_limiter_time_windows() :: [
    {activity_direct, temporal_sdk_limiter:time_window()}
    | {activity_eager, temporal_sdk_limiter:time_window()}
    | {activity_regular, temporal_sdk_limiter:time_window()}
    | {activity_session, temporal_sdk_limiter:time_window()}
    | {nexus, temporal_sdk_limiter:time_window()}
    | {workflow, temporal_sdk_limiter:time_window()}
].
-export_type([user_limiter_time_windows/0]).

-define(DEFAULT_LIMITER_TIME_WINDOW, 60_000).

-define(DEFAULT_TELEMETRY_EVENTS, [
    [grpc],
    [poller, poll],
    [poller, execute],
    [poller, wait],
    [activity],
    [activity, executor],
    [activity, task],
    [workflow, executor],
    [workflow, task],
    [workflow, execution]
]).

-define(DEFAULT_TELEMETRY_LOGS_LEVELS, #{stop => false, exception => error}).

%% -------------------------------------------------------------------------------------------------
%% API

-spec stats() -> temporal_sdk_limiter:stats().
stats() -> temporal_sdk_limiter:get_concurrency(get_counters(node)).

-spec os_stats() -> temporal_sdk_limiter:stats().
os_stats() -> temporal_sdk_limiter_os:get_stats(get_counters(os)).

-spec os_disk_mounts() -> [Id :: string()].
os_disk_mounts() -> get_disk_mounts().

-doc false.
-spec setup(LimiterId :: atom(), UserOpts :: opts() | user_opts()) ->
    {ok, LimiterCounters :: temporal_sdk_limiter:counters(),
        LimiterChildSpecs :: [supervisor:child_spec()], NodeOpts :: opts()}
    | {error, {invalid_opts, map()}}.
setup(LimiterId, UserOpts) ->
    case temporal_sdk_utils_opts:build(defaults(user_opts), UserOpts) of
        {ok, #{limiter_time_windows := TimeWindows} = Opts} ->
            {NodeCounters, NodeChiSpec} = temporal_sdk_limiter:setup(
                {LimiterId}, TimeWindows
            ),
            {OsCounters, OsChiSpec, DiskMounts} = temporal_sdk_limiter_os:setup(),
            persist_counters(NodeCounters, OsCounters),
            persist_disk_mounts(DiskMounts),
            {ok, #{os => OsCounters, node => NodeCounters}, [NodeChiSpec, OsChiSpec], Opts};
        {ok, InvalidOpts} ->
            {error, {invalid_opts, InvalidOpts}};
        Err ->
            Err
    end.

defaults(user_opts) ->
    [
        {limiter_time_windows, nested, defaults(limiter_time_windows)},
        {workflow_scope_partitions_size, list, []},
        {enable_single_distributed_workflow_execution, boolean, true},
        {telemetry_poll_interval, time, 10_000},
        {telemetry_logs, map,
            #{events => ?DEFAULT_TELEMETRY_EVENTS, log_levels => ?DEFAULT_TELEMETRY_LOGS_LEVELS},
            merge},
        {telemetry_metrics, list, ?DEFAULT_TELEMETRY_EVENTS},
        {telemetry_traces, list, ?DEFAULT_TELEMETRY_EVENTS}
    ];
defaults(limiter_time_windows) ->
    [
        {activity_direct, time, ?DEFAULT_LIMITER_TIME_WINDOW},
        {activity_eager, time, ?DEFAULT_LIMITER_TIME_WINDOW},
        {activity_regular, time, ?DEFAULT_LIMITER_TIME_WINDOW},
        {activity_session, time, ?DEFAULT_LIMITER_TIME_WINDOW},
        {nexus, time, ?DEFAULT_LIMITER_TIME_WINDOW},
        {workflow, time, ?DEFAULT_LIMITER_TIME_WINDOW}
    ].

persist_counters(NodeCounters, OsCounters) ->
    persistent_term:put({?MODULE, node_counters}, NodeCounters),
    persistent_term:put({?MODULE, os_counters}, OsCounters).

persist_disk_mounts(DiskMounts) -> persistent_term:put({?MODULE, os_disk_mounts}, DiskMounts).

-doc false.
get_counters(node) -> persistent_term:get({?MODULE, node_counters});
get_counters(os) -> persistent_term:get({?MODULE, os_counters}).

get_disk_mounts() -> persistent_term:get({?MODULE, os_disk_mounts}).
