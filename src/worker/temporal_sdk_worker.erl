-module(temporal_sdk_worker).

% elp:ignore W0012 W0040
-moduledoc {file, "../../docs/worker/worker/-module.md"}.

-export([
    count/2,
    is_alive/3,
    list/2,
    options/3,
    stats/3,
    get_limits/3,
    set_limits/4,
    set_limits/5,
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
        limiter_time_windows =>
            limiter_time_windows_activity()
            | limiter_time_windows_workflow()
            | limiter_time_windows_session()
            | limiter_time_windows_nexus(),
        telemetry_poll_interval => temporal_sdk:time()
    }.
-export_type([opts/0]).

-type user_opts() ::
    [
        {worker_id, worker_id()}
        | {namespace, unicode:chardata()}
        | {task_queue, unicode:chardata() | session_task_queue_name_fun()}
        | {task_settings, task_settings() | user_task_settings()}
        | {worker_version, worker_version()}
        | {allowed_temporal_names, allowed_temporal_names()}
        | {allowed_erlang_modules, allowed_erlang_modules()}
        | {temporal_name_to_erlang, temporal_name_to_erlang()}
        | {task_poller_pool_size, pos_integer()}
        | {task_poller_limiter, task_poller_limiter()}
        | {limits,
            temporal_sdk_limiter:levels_limits()
            | temporal_sdk_limiter:user_levels_limits()}
        | {limiter_check_frequency, pos_integer()}
        | {limiter_time_windows,
            limiter_time_windows_activity()
            | limiter_time_windows_workflow()
            | limiter_time_windows_session()
            | limiter_time_windows_nexus()
            | user_limiter_time_windows_activity()
            | user_limiter_time_windows_workflow()
            | user_limiter_time_windows_session()
            | user_limiter_time_windows_nexus()}
        | {telemetry_poll_interval, temporal_sdk:time()}
    ].
-export_type([user_opts/0]).

-type session_task_queue_name_fun() ::
    fun(
        (
            Cluster :: temporal_sdk_cluster:cluster_name(),
            Namespace :: unicode:chardata(),
            ParentTaskQueueName :: unicode:chardata()
        ) -> unicode:chardata()
    ).
-export_type([session_task_queue_name_fun/0]).

-type task_settings() :: activity_settings() | nexus_settings() | workflow_settings().
-export_type([task_settings/0]).

-type user_task_settings() ::
    activity_settings()
    | nexus_settings()
    | workflow_settings()
    | user_activity_settings()
    | user_nexus_settings()
    | user_workflow_settings().
-export_type([user_task_settings/0]).

-type activity_settings() :: #{
    data => temporal_sdk_activity:data(),
    last_heartbeat => temporal_sdk_activity:heartbeat(),
    heartbeat_timeout_ratio => float(),
    schedule_to_close_timeout_ratio => float(),
    start_to_close_timeout_ratio => float()
}.
-export_type([activity_settings/0]).

-type user_activity_settings() :: [
    {data, temporal_sdk_activity:data()}
    | {last_heartbeat, temporal_sdk_activity:heartbeat()}
    | {heartbeat_timeout_ratio, float()}
    | {schedule_to_close_timeout_ratio, float()}
    | {start_to_close_timeout_ratio, float()}
].
-export_type([user_activity_settings/0]).

-type nexus_settings() :: #{
    data => temporal_sdk_nexus:data(),
    task_timeout_ratio => float(),
    error_type => unicode:chardata()
}.

-type user_nexus_settings() :: [
    {data, temporal_sdk_nexus:data()}
    | {task_timeout_ratio, float()}
    | {error_type, unicode:chardata()}
].

-type workflow_settings() :: #{
    execution_id => temporal_sdk_workflow:execution_id(),
    deterministic_check_mod => module(),
    run_timeout_ratio => float(),
    task_timeout_ratio => float(),
    sticky_execution_schedule_to_start_ratio => float(),
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

-type user_workflow_settings() :: [
    {execution_id, temporal_sdk_workflow:execution_id()}
    | {deterministic_check_mod, module()}
    | {run_timeout_ratio, float()}
    | {task_timeout_ratio, float()}
    | {sticky_execution_schedule_to_start_ratio, float()}
    | {maximum_page_size, pos_integer()}
    | {await_open_before_close, boolean()}
    | {otp_messages_limits, [
        {received, pos_integer() | infinity}
        | {recorded, pos_integer() | infinity}
        | {ignored, pos_integer() | infinity}
    ]}
    | {eager_execution_settings, activity_settings() | user_activity_settings()}
    | {session_worker, opts() | user_opts() | boolean()}
].
-export_type([user_workflow_settings/0]).

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

-type limiter_time_windows_activity() :: #{
    activity_regular => temporal_sdk_limiter:time_window()
}.
-export_type([limiter_time_windows_activity/0]).

-type user_limiter_time_windows_activity() :: [
    {activity_regular, temporal_sdk_limiter:time_window()}
].
-export_type([user_limiter_time_windows_activity/0]).

-type limiter_time_windows_workflow() :: #{
    activity_direct => temporal_sdk_limiter:time_window(),
    activity_eager => temporal_sdk_limiter:time_window(),
    workflow => temporal_sdk_limiter:time_window()
}.
-export_type([limiter_time_windows_workflow/0]).

-type user_limiter_time_windows_workflow() :: [
    {activity_eager, temporal_sdk_limiter:time_window()}
    | {activity_regular, temporal_sdk_limiter:time_window()}
    | {workflow, temporal_sdk_limiter:time_window()}
].
-export_type([user_limiter_time_windows_workflow/0]).

-type limiter_time_windows_session() :: #{
    activity_session => temporal_sdk_limiter:time_window()
}.
-export_type([limiter_time_windows_session/0]).

-type user_limiter_time_windows_session() :: [
    {activity_session, temporal_sdk_limiter:time_window()}
].
-export_type([user_limiter_time_windows_session/0]).

-type limiter_time_windows_nexus() :: #{
    nexus => temporal_sdk_limiter:time_window()
}.
-export_type([limiter_time_windows_nexus/0]).

-type user_limiter_time_windows_nexus() :: [
    {nexus, temporal_sdk_limiter:time_window()}
].
-export_type([user_limiter_time_windows_nexus/0]).

-type limiter_limits() :: #{
    task_poller_limiter => task_poller_limiter(),
    limits => temporal_sdk_limiter:levels_limits(),
    limiter_check_frequency => pos_integer()
}.
-export_type([limiter_limits/0]).

-type invalid_error() :: {error, invalid_cluster | invalid_worker}.
-export_type([invalid_error/0]).

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

-spec is_alive(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: worker_type(),
    WorkerId :: worker_id()
) -> boolean().
is_alive(Cluster, session, WorkerId) ->
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
is_alive(Cluster, WorkerType, WorkerId) ->
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

-spec get_limits(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: worker_type(),
    WorkerId :: worker_id()
) -> {ok, limiter_limits()} | invalid_error().
get_limits(Cluster, session, WorkerId) ->
    case options(Cluster, workflow, WorkerId) of
        {ok, #{task_settings := #{session_worker := SW}}} when is_map(SW) ->
            {ok, maps:with([task_poller_limiter, limits, limiter_check_frequency], SW)};
        {ok, #{}} ->
            {error, invalid_worker};
        {error, _} = Err ->
            Err
    end;
get_limits(Cluster, WorkerType, WorkerId) ->
    case options(Cluster, WorkerType, WorkerId) of
        {ok, O} -> {ok, maps:with([task_poller_limiter, limits, limiter_check_frequency], O)};
        {error, _} = Err -> Err
    end.

-spec set_limits(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: worker_type(),
    WorkerId :: worker_id(),
    Limits :: limiter_limits()
) -> ok | invalid_worker | invalid_state.
set_limits(Cluster, session, WorkerId, Limits) ->
    maybe
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
        PollerPids = lists:map(fun({_, P, worker, [temporal_sdk_poller]}) -> P end, PollerChi),
        gen_server:cast(OptsPid, {set_session_limits, Limits}),
        lists:foreach(
            fun(P) when is_pid(P) -> gen_statem:cast(P, {set_limits, Limits}) end, PollerPids
        )
    else
        false -> invalid_worker;
        _ -> invalid_state
    end;
set_limits(Cluster, WorkerType, WorkerId, Limits) ->
    maybe
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
        PollerPids = lists:map(fun({_, P, worker, [temporal_sdk_poller]}) -> P end, PollerChi),
        gen_server:cast(OptsPid, {set_limits, Limits}),
        lists:foreach(
            fun(P) when is_pid(P) -> gen_statem:cast(P, {set_limits, Limits}) end, PollerPids
        )
    else
        false -> invalid_worker;
        _ -> invalid_state
    end.

-spec set_limits(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: worker_type(),
    WorkerId :: worker_id(),
    Limits :: limiter_limits(),
    Nodes :: [node()]
) -> ok.
set_limits(Cluster, WorkerType, WorkerId, Limits, Nodes) ->
    erpc:multicast(Nodes, ?MODULE, set_limits, [Cluster, WorkerType, WorkerId, Limits]).

-spec start(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: activity | nexus | workflow,
    WorkerOpts :: user_opts() | opts()
) ->
    {ok, opts()}
    | {invalid_opts, map()}
    | invalid_error()
    | supervisor:startchild_ret().
start(Cluster, WorkerType, WorkerOpts) ->
    temporal_sdk_worker_manager_sup:start_worker(Cluster, WorkerType, WorkerOpts, false).

-spec start(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: activity | nexus | workflow,
    WorkerOpts :: user_opts() | opts(),
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
