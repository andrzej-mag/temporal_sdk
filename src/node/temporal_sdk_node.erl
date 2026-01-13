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

-doc """
SDK configuration options.
""".
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

-doc """
SDK node configuration options as a map.
""".
-type opts() :: #{
    enable_single_distributed_workflow_execution => boolean(),
    scope_config => [scope_config()],
    limiter_time_windows => limiter_time_windows() | user_limiter_time_windows(),
    telemetry_poll_interval => temporal_sdk:time(),
    telemetry_events_handlers => temporal_sdk_telemetry:events_handlers()
}.
-export_type([opts/0]).

-doc """
SDK node configuration options as a proplist.
""".
-type user_opts() :: [
    {enable_single_distributed_workflow_execution, boolean()}
    | enable_single_distributed_workflow_execution
    | {scope_config, [scope_config()]}
    | {limiter_time_windows, limiter_time_windows() | user_limiter_time_windows()}
    | {telemetry_poll_interval, temporal_sdk:time()}
    | {telemetry_events_handlers, temporal_sdk_telemetry:events_handlers()}
].
-export_type([user_opts/0]).

-doc """
SDK node scope configuration options.
""".
-type scope_config() :: {
    ScopeId :: temporal_sdk_cluster:cluster_name(), ShardSize :: pos_integer()
}.
-export_type([scope_config/0]).

-doc """
SDK node fixed window rate limiter time windows configuration as a map.
""".
-type limiter_time_windows() :: #{
    activity_direct => temporal_sdk_limiter:time_window(),
    activity_eager => temporal_sdk_limiter:time_window(),
    activity_regular => temporal_sdk_limiter:time_window(),
    activity_session => temporal_sdk_limiter:time_window(),
    nexus => temporal_sdk_limiter:time_window(),
    workflow => temporal_sdk_limiter:time_window()
}.
-export_type([limiter_time_windows/0]).

-doc """
SDK node fixed window rate limiter time windows configuration as a proplist.
""".
-type user_limiter_time_windows() :: [
    {activity_direct, temporal_sdk_limiter:time_window()}
    | {activity_eager, temporal_sdk_limiter:time_window()}
    | {activity_regular, temporal_sdk_limiter:time_window()}
    | {activity_session, temporal_sdk_limiter:time_window()}
    | {nexus, temporal_sdk_limiter:time_window()}
    | {workflow, temporal_sdk_limiter:time_window()}
].
-export_type([user_limiter_time_windows/0]).

-define(DEFAULT_LIMITER_TIME_WINDOW, temporal_sdk_limiter:default_time_window()).

%% -------------------------------------------------------------------------------------------------
%% API

-doc {file, "../../docs/node/stats-0.md"}.
-spec stats() -> temporal_sdk_limiter:stats().
stats() -> temporal_sdk_limiter:get_concurrency(get_counters(node)).

-doc {file, "../../docs/node/os_stats-0.md"}.
-spec os_stats() -> temporal_sdk_limiter:stats().
os_stats() -> temporal_sdk_limiter_os:get_stats(get_counters(os)).

-doc {file, "../../docs/node/os_disk_mounts-0.md"}.
-spec os_disk_mounts() -> [Id :: string()].
os_disk_mounts() -> get_disk_mounts().

%% -------------------------------------------------------------------------------------------------
%% internal

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
        {scope_config, list, []},
        {enable_single_distributed_workflow_execution, boolean, true},
        {telemetry_poll_interval, time, 10_000},
        {telemetry_events_handlers, list, [
            {
                fun() -> temporal_sdk_telemetry:events_by_suffix([exception]) end,
                fun temporal_sdk_telemetry:handle_log/4
            }
        ]}
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
