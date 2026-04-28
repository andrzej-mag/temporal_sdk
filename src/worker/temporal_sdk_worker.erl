-module(temporal_sdk_worker).

% elp:ignore W0012 W0040 E1599
-moduledoc {file, "../../docs/worker/-module.md"}.

-export([
    count/2,
    is_started/3,
    list/2,
    options/3,
    stats/3,
    get_limiter_config/3,
    set_limiter_config/4,
    set_limiter_config/5,
    start/3,
    start/4,
    terminate/3,
    terminate/4
]).

-include("proto.hrl").

-type worker_type() :: activity | nexus | session | workflow.
-export_type([worker_type/0]).

-type id() :: atom() | unicode:chardata().
-export_type([id/0]).

-type worker_id() :: atom() | unicode:chardata().
-export_type([worker_id/0]).

-type opts() ::
    #{
        worker_id => worker_id(),
        namespace => unicode:chardata(),
        task_queue := unicode:chardata() | session_task_queue_name_fun(),
        task_settings => task_settings(),
        worker_version => worker_version(),
        allowed_temporal_names => allowed_temporal_names(),
        allowed_erlang_modules => allowed_erlang_modules(),
        temporal_name_to_erlang => temporal_name_to_erlang(),
        task_poller_pool_size => pos_integer(),
        task_poller_limiter => task_poller_limiter(),
        limits => temporal_sdk_limiter:levels_limits(),
        limiter_check_frequency => pos_integer(),
        limiter_time_windows => limiter_time_windows(),
        telemetry_poll_interval => temporal_sdk:time(),
        disable_telemetry => boolean()
    }.
-export_type([opts/0]).

-type opts_as_list() ::
    [
        {worker_id, worker_id()}
        | {namespace, unicode:chardata()}
        | {task_queue, unicode:chardata() | session_task_queue_name_fun()}
        | {task_settings, task_settings()}
        | {worker_version, worker_version()}
        | {allowed_temporal_names, allowed_temporal_names()}
        | {allowed_erlang_modules, allowed_erlang_modules()}
        | {temporal_name_to_erlang, temporal_name_to_erlang()}
        | {task_poller_pool_size, pos_integer()}
        | {task_poller_limiter, task_poller_limiter()}
        | {limits,
            temporal_sdk_limiter:levels_limits() | temporal_sdk_limiter:levels_limits_as_list()}
        | {limiter_check_frequency, pos_integer()}
        | {limiter_time_windows, limiter_time_windows()}
        | {telemetry_poll_interval, temporal_sdk:time()}
        | {disable_telemetry, boolean()}
        | disable_telemetry
    ].
-export_type([opts_as_list/0]).

-type session_task_queue_name_fun() ::
    fun(
        (
            Cluster :: temporal_sdk_cluster:cluster_name(),
            Namespace :: unicode:chardata(),
            ParentTaskQueueName :: unicode:chardata()
        ) -> unicode:chardata()
    ).
-export_type([session_task_queue_name_fun/0]).

-type task_settings() ::
    activity_settings()
    | activity_settings_as_list()
    | nexus_settings()
    | nexus_settings_as_list()
    | workflow_settings()
    | workflow_settings_as_list().
-export_type([task_settings/0]).

-type activity_settings() :: #{
    data => temporal_sdk_activity:data(),
    last_heartbeat => temporal_sdk_activity:heartbeat(),
    heartbeat_timeout_ratio => float(),
    schedule_to_close_timeout_ratio => float(),
    start_to_close_timeout_ratio => float()
}.
-export_type([activity_settings/0]).

-type activity_settings_as_list() :: [
    {data, temporal_sdk_activity:data()}
    | {last_heartbeat, temporal_sdk_activity:heartbeat()}
    | {heartbeat_timeout_ratio, float()}
    | {schedule_to_close_timeout_ratio, float()}
    | {start_to_close_timeout_ratio, float()}
].
-export_type([activity_settings_as_list/0]).

-type nexus_settings() :: #{
    data => temporal_sdk_nexus:data(),
    task_timeout_ratio => float(),
    error_type => unicode:chardata()
}.
-export_type([nexus_settings/0]).

-type nexus_settings_as_list() :: [
    {data, temporal_sdk_nexus:data()}
    | {task_timeout_ratio, float()}
    | {error_type, unicode:chardata()}
].
-export_type([nexus_settings_as_list/0]).

-type workflow_settings() :: #{
    execution_id => temporal_sdk_workflow:execution_id(),
    deterministic_check_mod => module(),
    run_timeout_ratio => float(),
    task_timeout_ratio => float(),
    sticky_execution => sticky_execution() | sticky_execution_as_list(),
    maximum_page_size => pos_integer(),
    await_open_before_close => boolean(),
    otp_messages_limits => [
        {received, pos_integer() | infinity}
        | {recorded, pos_integer() | infinity}
        | {ignored, pos_integer() | infinity}
    ],
    eager_execution_settings => activity_settings(),
    session_worker => opts() | boolean()
}.
-export_type([workflow_settings/0]).

-type workflow_settings_as_list() :: [
    {execution_id, temporal_sdk_workflow:execution_id()}
    | {deterministic_check_mod, module()}
    | {run_timeout_ratio, float()}
    | {task_timeout_ratio, float()}
    | {sticky_execution, sticky_execution() | sticky_execution_as_list()}
    | {maximum_page_size, pos_integer()}
    | {await_open_before_close, boolean()}
    | {otp_messages_limits, [
        {received, pos_integer() | infinity}
        | {recorded, pos_integer() | infinity}
        | {ignored, pos_integer() | infinity}
    ]}
    | {eager_execution_settings, activity_settings() | activity_settings_as_list()}
    | {session_worker, opts() | opts_as_list() | boolean()}
].
-export_type([workflow_settings_as_list/0]).

-type sticky_execution() ::
    #{
        type := local | pool | disabled,
        schedule_to_start_timeout => temporal_sdk:time(),
        pool_size => pos_integer(),
        queue_name => unicode:chardata(),
        task_poller_limiter => task_poller_limiter(),
        limits => temporal_sdk_limiter:levels_limits()
    }.
-export_type([sticky_execution/0]).

-type sticky_execution_as_list() ::
    [
        {type, local | pool | disabled}
        | {schedule_to_start_timeout, temporal_sdk:time()}
        | {pool_size, pos_integer()}
        | {queue_name, unicode:chardata()}
        | {task_poller_limiter, task_poller_limiter()}
        | {limits, temporal_sdk_limiter:levels_limits()}
    ].
-export_type([sticky_execution_as_list/0]).

-type worker_version() :: ?TEMPORAL_SPEC:'temporal.api.common.v1.WorkerVersionStamp'().
-export_type([worker_version/0]).

-type allowed_temporal_names() :: all | [unicode:chardata()].
-export_type([allowed_temporal_names/0]).

-type allowed_erlang_modules() :: all | [module()].
-export_type([allowed_erlang_modules/0]).

-type temporal_name_to_erlang() :: fun(
    (Cluster :: temporal_sdk_cluster:cluster_name(), TemporalTypeName :: unicode:chardata()) ->
        {ok, module()} | {error, Reason :: term()}
).
-export_type([temporal_name_to_erlang/0]).

-type task_poller_limiter() ::
    #{limit := pos_integer() | infinity, time_window := temporal_sdk:time() | undefined}.
-export_type([task_poller_limiter/0]).

-type limiter_time_windows() ::
    limiter_time_windows_activity()
    | limiter_time_windows_activity_as_list()
    | limiter_time_windows_nexus()
    | limiter_time_windows_nexus_as_list()
    | limiter_time_windows_session()
    | limiter_time_windows_session_as_list()
    | limiter_time_windows_workflow()
    | limiter_time_windows_workflow_as_list().

-type limiter_time_windows_activity() :: #{
    activity_regular => temporal_sdk_limiter:time_window()
}.
-export_type([limiter_time_windows_activity/0]).

-type limiter_time_windows_activity_as_list() :: [
    {activity_regular, temporal_sdk_limiter:time_window()}
].
-export_type([limiter_time_windows_activity_as_list/0]).

-type limiter_time_windows_workflow() :: #{
    activity_direct => temporal_sdk_limiter:time_window(),
    activity_eager => temporal_sdk_limiter:time_window(),
    workflow => temporal_sdk_limiter:time_window()
}.
-export_type([limiter_time_windows_workflow/0]).

-type limiter_time_windows_workflow_as_list() :: [
    {activity_eager, temporal_sdk_limiter:time_window()}
    | {activity_regular, temporal_sdk_limiter:time_window()}
    | {workflow, temporal_sdk_limiter:time_window()}
].
-export_type([limiter_time_windows_workflow_as_list/0]).

-type limiter_time_windows_session() :: #{
    activity_session => temporal_sdk_limiter:time_window()
}.
-export_type([limiter_time_windows_session/0]).

-type limiter_time_windows_session_as_list() :: [
    {activity_session, temporal_sdk_limiter:time_window()}
].
-export_type([limiter_time_windows_session_as_list/0]).

-type limiter_time_windows_nexus() :: #{
    nexus => temporal_sdk_limiter:time_window()
}.
-export_type([limiter_time_windows_nexus/0]).

-type limiter_time_windows_nexus_as_list() :: [
    {nexus, temporal_sdk_limiter:time_window()}
].
-export_type([limiter_time_windows_nexus_as_list/0]).

-doc """
Dynamic configuration of the rate limiter.

Use `get_limiter_config/3` to retrieve and `set_limiter_config/4` to update the dynamic configuration
of rate limiters.
See `start/3` for descriptions of the configuration options.
""".
-type limiter_config() :: #{
    task_poller_limiter => task_poller_limiter(),
    limits => temporal_sdk_limiter:levels_limits(),
    limiter_check_frequency => pos_integer()
}.
-export_type([limiter_config/0]).

-type limiter_config_as_list() :: [
    {task_poller_limiter, task_poller_limiter()}
    | {limits, temporal_sdk_limiter:levels_limits()}
    | {limiter_check_frequency, pos_integer()}
].
-export_type([limiter_config_as_list/0]).

-type invalid_error() :: {error, invalid_cluster | invalid_worker}.
-export_type([invalid_error/0]).

-type set_limiter_config_ret() ::
    ok
    | {error, {invalid_opts, map()}}
    | invalid_worker
    | invalid_state.
-export_type([set_limiter_config_ret/0]).

%% -------------------------------------------------------------------------------------------------
%% public

-spec count(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: activity | nexus | workflow
) -> {ok, non_neg_integer()} | invalid_error().
count(Cluster, WorkerType) ->
    case temporal_sdk_worker_registry:count_names(Cluster, WorkerType) of
        {error, _} = Err -> Err;
        V -> {ok, V}
    end.

-spec is_started(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: worker_type(),
    WorkerId :: worker_id()
) -> boolean().
is_started(Cluster, session, WorkerId) ->
    case temporal_sdk_worker_registry:whereis_name({Cluster, workflow, WorkerId}) of
        undefined ->
            false;
        Pid ->
            Chi = supervisor:which_children(Pid),
            case lists:keyfind({temporal_sdk_poller_sup, Cluster, session, WorkerId}, 1, Chi) of
                {{temporal_sdk_poller_sup, Cluster, session, WorkerId}, _Pid, supervisor, [
                    temporal_sdk_poller_sup
                ]} ->
                    true;
                _ ->
                    false
            end
    end;
is_started(Cluster, WorkerType, WorkerId) ->
    case temporal_sdk_worker_registry:whereis_name({Cluster, WorkerType, WorkerId}) of
        undefined -> false;
        _Pid -> true
    end.

-spec list(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: activity | nexus | workflow
) -> {ok, [worker_id()]} | invalid_error().
list(Cluster, WorkerType) ->
    case temporal_sdk_worker_registry:registered_names(Cluster, WorkerType) of
        {error, _} = Err -> Err;
        V -> {ok, V}
    end.

-spec options(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: worker_type(),
    WorkerId :: worker_id()
) -> {ok, opts()} | invalid_error().
options(Cluster, WorkerType, WorkerId) ->
    temporal_sdk_worker_opts:get_opts(Cluster, WorkerType, WorkerId).

-spec stats(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: worker_type(),
    WorkerId :: worker_id()
) -> {ok, temporal_sdk_limiter:stats()} | invalid_error().
stats(Cluster, WorkerType, WorkerId) ->
    temporal_sdk_worker_opts:stats(Cluster, WorkerType, WorkerId).

-doc {file, "../../docs/worker/get_limiter_config-3.md"}.
-spec get_limiter_config(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: worker_type(),
    WorkerId :: worker_id()
) -> {ok, limiter_config()} | invalid_error().
get_limiter_config(Cluster, session, WorkerId) ->
    case options(Cluster, workflow, WorkerId) of
        {ok, #{task_settings := #{session_worker := SW}}} when is_map(SW) ->
            {ok, maps:with([task_poller_limiter, limits, limiter_check_frequency], SW)};
        {ok, #{}} ->
            {error, invalid_worker};
        {error, _} = Err ->
            Err
    end;
get_limiter_config(Cluster, WorkerType, WorkerId) ->
    case options(Cluster, WorkerType, WorkerId) of
        {ok, O} -> {ok, maps:with([task_poller_limiter, limits, limiter_check_frequency], O)};
        {error, _} = Err -> Err
    end.

-doc {file, "../../docs/worker/set_limiter_config-4.md"}.
-spec set_limiter_config(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: worker_type(),
    WorkerId :: worker_id(),
    NewLimiterConfig :: limiter_config() | limiter_config_as_list()
) -> set_limiter_config_ret().
set_limiter_config(Cluster, session, WorkerId, NewLimiterConfig) ->
    maybe
        {ok, Limits} ?= temporal_sdk_worker_opts:build_limiter_config(session, NewLimiterConfig),
        Pid = temporal_sdk_worker_registry:whereis_name({Cluster, workflow, WorkerId}),
        true ?= is_pid(Pid),
        Chi = supervisor:which_children(Pid),
        {{temporal_sdk_worker_opts, Cluster, workflow, WorkerId}, OptsPid, worker, [
            temporal_sdk_worker_opts
        ]} ?= lists:keyfind([temporal_sdk_worker_opts], 4, Chi),
        {{temporal_sdk_poller_sup, Cluster, session, WorkerId}, PollerPid, supervisor, [
            temporal_sdk_poller_sup
        ]} ?= lists:keyfind({temporal_sdk_poller_sup, Cluster, session, WorkerId}, 1, Chi),
        PollerChi = supervisor:which_children(PollerPid),
        PollerPids = [P || {_, P, worker, [temporal_sdk_poller]} <- PollerChi],
        gen_server:cast(OptsPid, {set_session_limits, Limits}),
        lists:foreach(
            fun(P) when is_pid(P) -> gen_statem:cast(P, {set_limits, Limits}) end, PollerPids
        )
    else
        false -> invalid_worker;
        {error, _} = Err -> Err;
        _ -> invalid_state
    end;
set_limiter_config(Cluster, WorkerType, WorkerId, NewLimiterConfig) ->
    maybe
        {ok, Limits} ?= temporal_sdk_worker_opts:build_limiter_config(WorkerType, NewLimiterConfig),
        Pid = temporal_sdk_worker_registry:whereis_name({Cluster, WorkerType, WorkerId}),
        true ?= is_pid(Pid),
        Chi = supervisor:which_children(Pid),
        {{temporal_sdk_worker_opts, Cluster, WorkerType, WorkerId}, OptsPid, worker, [
            temporal_sdk_worker_opts
        ]} ?= lists:keyfind([temporal_sdk_worker_opts], 4, Chi),
        {{temporal_sdk_poller_sup, Cluster, WorkerType, WorkerId}, PollerPid, supervisor, [
            temporal_sdk_poller_sup
        ]} ?= lists:keyfind({temporal_sdk_poller_sup, Cluster, WorkerType, WorkerId}, 1, Chi),
        PollerChi = supervisor:which_children(PollerPid),
        PollerPids = [P || {_, P, worker, [temporal_sdk_poller]} <- PollerChi],
        gen_server:cast(OptsPid, {set_limits, Limits}),
        lists:foreach(
            fun(P) when is_pid(P) -> gen_statem:cast(P, {set_limits, Limits}) end, PollerPids
        )
    else
        false -> invalid_worker;
        {error, _} = Err -> Err;
        _ -> invalid_state
    end.

-doc {file, "../../docs/worker/set_limiter_config-5.md"}.
-spec set_limiter_config(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: worker_type(),
    WorkerId :: worker_id(),
    NewLimiterConfig :: limiter_config() | limiter_config_as_list(),
    Nodes :: [node()]
) -> ok | [{ok, set_limiter_config_ret()} | {error, {erpc, Reason :: term()}} | term()].
set_limiter_config(Cluster, WorkerType, WorkerId, NewLimiterConfig, Nodes) ->
    ErpcResult = erpc:multicall(Nodes, ?MODULE, set_limiter_config, [
        Cluster, WorkerType, WorkerId, NewLimiterConfig
    ]),
    case lists:uniq(ErpcResult) of
        [{ok, ok}] -> ok;
        _ -> ErpcResult
    end.

-spec start(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: activity | nexus | workflow,
    WorkerOpts :: opts() | opts_as_list()
) ->
    {ok, opts()}
    | {invalid_opts, map()}
    | invalid_error()
    | supervisor:startchild_ret().
start(Cluster, WorkerType, WorkerOpts) ->
    temporal_sdk_worker_manager_sup:start_worker(Cluster, WorkerType, WorkerOpts).

-spec start(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: activity | nexus | workflow,
    WorkerOpts :: opts() | opts_as_list(),
    Nodes :: [node()]
) -> ok.
start(Cluster, WorkerType, WorkerOpts, Nodes) ->
    erpc:multicast(Nodes, ?MODULE, start, [Cluster, WorkerType, WorkerOpts]).

-spec terminate(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: activity | nexus | workflow,
    WorkerId :: worker_id()
) -> ok | {error, invalid_cluster | not_found | simple_one_for_one}.
terminate(Cluster, WorkerType, WorkerId) ->
    temporal_sdk_worker_manager_sup:terminate_worker(Cluster, WorkerType, WorkerId).

-spec terminate(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: activity | nexus | workflow,
    WorkerId :: worker_id(),
    Nodes :: [node()]
) -> ok.
terminate(Cluster, WorkerType, WorkerId, Nodes) ->
    erpc:multicast(Nodes, ?MODULE, terminate, [Cluster, WorkerType, WorkerId]).
