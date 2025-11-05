-module(temporal_sdk_worker_opts).
-behaviour(gen_server).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    setup/3,
    get_opts/3,
    stats/3,
    worker_type_to_limitable/1
]).
-export([
    setup_replay/2,
    start_link/2,
    get_state/3
]).
-export([
    init/1,
    handle_call/3,
    handle_cast/2
]).

-define(DEFAULT_LIMITER_TIME_WINDOW, 60_000).

%% -------------------------------------------------------------------------------------------------
%% API

-spec setup(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: activity | nexus | workflow,
    WorkerOpts :: temporal_sdk_worker:user_opts() | temporal_sdk_worker:opts()
) ->
    {ok, LimiterCounter :: temporal_sdk_limiter:counter(),
        LimiterChildSpecs :: [supervisor:child_spec()], Opts :: temporal_sdk_worker:opts()}
    | {error, {invalid_opts, map()}}
    | temporal_sdk_worker:invalid_error().
setup(Cluster, WorkerType, WorkerOpts) when
    WorkerType =:= activity; WorkerType =:= nexus; WorkerType =:= workflow
->
    maybe
        {ok, O0} ?= temporal_sdk_utils_opts:build(defaults(worker_opts, WorkerType), WorkerOpts),
        #{worker_id := WorkerId, limiter_time_windows := TimeWindows} = O1 = add_worker_id(O0),
        {ok, Opts, SCounters, SChiSpec} ?= setup_session(WorkerType, Cluster, O1),
        {WCounters, WChiSpec} = temporal_sdk_limiter:setup(
            {Cluster, WorkerType, WorkerId}, TimeWindows
        ),
        {ok, merge_session_counters(SCounters, WCounters), lists:flatten([WChiSpec, SChiSpec]),
            Opts}
    else
        Err -> Err
    end;
setup(_Cluster, _WorkerType, _WorkerOpts) ->
    {error, invalid_worker}.

merge_session_counters([], WCounters) -> #{worker => WCounters};
merge_session_counters(#{} = SCounters, WCounters) -> #{worker => WCounters, session => SCounters}.

-spec setup_replay(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerOpts :: temporal_sdk_worker:user_opts() | temporal_sdk_worker:opts()
) ->
    {ok, Opts :: temporal_sdk_worker:opts()}
    | {error, {invalid_opts, map()}}.
setup_replay(Cluster, WorkerOpts) ->
    case temporal_sdk_utils_opts:build(defaults(worker_opts, workflow), WorkerOpts) of
        {ok, Opts} -> setup_session(replay, Cluster, Opts);
        Err -> Err
    end.

setup_session(Type, Cluster, #{task_settings := TS = #{session_worker := true}} = Opts) ->
    setup_session(Type, Cluster, Opts#{task_settings := TS#{session_worker := []}});
setup_session(workflow, Cluster, #{task_settings := TS = #{session_worker := SW}} = Opts) when
    is_list(SW); is_map(SW)
->
    #{worker_id := WorkerId, namespace := Namespace, task_queue := TQ} = Opts,
    case temporal_sdk_utils_opts:build(defaults(worker_opts, session), SW) of
        {ok, #{task_queue := STQ, limiter_time_windows := TimeWindows} = SessionOpts} ->
            SO = SessionOpts#{
                worker_id => WorkerId,
                namespace => Namespace,
                task_queue := session_tq_name(STQ, Cluster, Namespace, TQ)
            },
            {SCounters, SChiSpec} = temporal_sdk_limiter:setup(
                {Cluster, session, WorkerId}, TimeWindows
            ),
            {ok, Opts#{task_settings := TS#{session_worker := SO}}, SCounters, SChiSpec};
        Err ->
            Err
    end;
setup_session(replay, Cluster, #{task_settings := TS = #{session_worker := SW}} = Opts) when
    is_list(SW); is_map(SW)
->
    #{namespace := NS, task_queue := TQ} = Opts,
    case temporal_sdk_utils_opts:build(defaults(worker_opts, session), SW) of
        {ok, #{task_queue := STQ} = SessionOpts} ->
            SO = SessionOpts#{namespace => NS, task_queue := session_tq_name(STQ, Cluster, NS, TQ)},
            {ok, Opts#{task_settings := TS#{session_worker := SO}}};
        Err ->
            Err
    end;
setup_session(replay, _Cluster, Opts) ->
    {ok, Opts};
setup_session(_Type, _Cluster, Opts) ->
    {ok, Opts, [], []}.

session_tq_name(STQ, Cluster, Namespace, TQ) when is_function(STQ, 3) ->
    STQ(Cluster, Namespace, TQ);
session_tq_name(STQ, _Cluster, _Namespace, _TQ) when is_function(STQ) ->
    "invalid_session_task_queue_name_fun";
session_tq_name(STQ, _Cluster, _Namespace, _TQ) ->
    STQ.

add_worker_id(#{worker_id := _} = Opts) ->
    Opts;
add_worker_id(#{namespace := NS, task_queue := TQ} = Opts) ->
    Opts#{worker_id => temporal_sdk_utils_path:string_path([NS, TQ])}.

-spec defaults(OptsType :: atom(), WorkerType :: temporal_sdk_worker:worker_type()) ->
    temporal_sdk_utils_opts:defaults().
defaults(worker_opts, session) ->
    [
        %% {worker_id, [atom, unicode], '$_optional'},
        %% {namespace, unicode, "default"},
        {task_queue, [unicode, function], fun temporal_sdk_api:session_task_queue_name/3},
        {task_settings, nested, defaults(task_settings, activity)},
        {worker_version, map, #{}},
        {allowed_temporal_names, [atom, list], all},
        {allowed_erlang_modules, [atom, list], all},
        {temporal_name_to_erlang, function, fun temporal_sdk_api:temporal_name_to_erlang/2},
        {task_poller_pool_size, pos_integer, task_poller_pool_size(session)},
        {task_poller_limiter, nested, defaults(task_poller_limiter, session)},
        {limits, nested, defaults(limits, session)},
        {limiter_check_frequency, pos_integer, 500},
        {limiter_time_windows, nested, defaults(limiter_time_windows, session)}
        %% {telemetry_poll_interval, time, 10_000}
    ];
defaults(worker_opts, WorkerType) ->
    [
        {worker_id, [atom, unicode], '$_optional'},
        {namespace, unicode, "default"},
        {task_queue, unicode, '$_required'},
        {task_settings, nested, defaults(task_settings, WorkerType)},
        {worker_version, map, #{}},
        {allowed_temporal_names, [atom, list], all},
        {allowed_erlang_modules, [atom, list], all},
        {temporal_name_to_erlang, function, fun temporal_sdk_api:temporal_name_to_erlang/2},
        {task_poller_pool_size, pos_integer, task_poller_pool_size(WorkerType)},
        {task_poller_limiter, nested, defaults(task_poller_limiter, WorkerType)},
        {limits, nested, defaults(limits, WorkerType)},
        {limiter_check_frequency, pos_integer, 500},
        {limiter_time_windows, nested, defaults(limiter_time_windows, WorkerType)},
        {telemetry_poll_interval, time, 10_000}
    ];
defaults(task_settings, activity) ->
    [
        {data, any, undefined},
        {last_heartbeat, list, [undefined]},
        {heartbeat_timeout_ratio, float, 0.8},
        {schedule_to_close_timeout_ratio, float, 0.8},
        {start_to_close_timeout_ratio, float, 0.8}
    ];
defaults(task_settings, nexus) ->
    [
        {data, any, undefined},
        {task_timeout_ratio, float, 0.8},
        {error_type, unicode, '$_optional'}
    ];
defaults(task_settings, workflow) ->
    [
        {execution_id, any, main},
        {deterministic_check_mod, atom, temporal_sdk_api_workflow_check_strict},
        {run_timeout_ratio, float, 0.8},
        {task_timeout_ratio, float, 0.8},
        {sticky_execution_schedule_to_start_ratio, float, 0.5},
        {maximum_page_size, pos_integer, 256},
        {await_open_before_close, boolean, true},
        {otp_messages_limits, list, [{received, infinity}, {recorded, 1_000}, {ignored, infinity}]},
        {eager_execution_settings, nested, defaults(task_settings, activity)},
        {session_worker, [boolean, map, list], true}
    ];
defaults(task_poller_limiter, _WorkerType) ->
    [
        {limit, [infinity, pos_integer], infinity},
        {time_window, [undefined, time], undefined}
    ];
defaults(limits, WorkerType) ->
    [
        {os, nested, defaults(os_limits, WorkerType)},
        {node, nested, defaults(node_limits, WorkerType)},
        {cluster, nested, defaults(cluster_limits, WorkerType)},
        {worker, nested, defaults(worker_limits, WorkerType)}
    ];
defaults(os_limits, _WorkerType) ->
    DiskLimits = lists:map(
        fun(Id) -> {{disk, Id}, pos_integer, '$_optional'} end, temporal_sdk_node:os_disk_mounts()
    ),
    % eqwalizer:ignore
    [
        {cpu1, pos_integer, '$_optional'},
        {cpu5, pos_integer, '$_optional'},
        {cpu15, pos_integer, '$_optional'},
        {mem, pos_integer, '$_optional'}
    ] ++ DiskLimits;
defaults(OptsType, _WorkerType) when OptsType =:= node_limits; OptsType =:= cluster_limits ->
    [
        {activity_direct, limiter_limits, '$_optional'},
        {activity_eager, limiter_limits, '$_optional'},
        {activity_regular, limiter_limits, '$_optional'},
        {activity_session, limiter_limits, '$_optional'},
        {nexus, limiter_limits, '$_optional'},
        {workflow, limiter_limits, '$_optional'}
    ];
defaults(worker_limits, activity) ->
    [
        {activity_regular, limiter_limits, '$_optional'}
    ];
defaults(worker_limits, session) ->
    [
        {activity_session, limiter_limits, '$_optional'}
    ];
defaults(worker_limits, workflow) ->
    [
        {activity_direct, limiter_limits, '$_optional'},
        {activity_eager, limiter_limits, '$_optional'},
        {workflow, limiter_limits, '$_optional'}
    ];
defaults(worker_limits, nexus) ->
    [
        {nexus, limiter_limits, '$_optional'}
    ];
defaults(limiter_time_windows, activity) ->
    [
        {activity_regular, time, ?DEFAULT_LIMITER_TIME_WINDOW}
    ];
defaults(limiter_time_windows, session) ->
    [
        {activity_session, time, ?DEFAULT_LIMITER_TIME_WINDOW}
    ];
defaults(limiter_time_windows, workflow) ->
    [
        {activity_direct, time, ?DEFAULT_LIMITER_TIME_WINDOW},
        {activity_eager, time, ?DEFAULT_LIMITER_TIME_WINDOW},
        {workflow, time, ?DEFAULT_LIMITER_TIME_WINDOW}
    ];
defaults(limiter_time_windows, nexus) ->
    [
        {nexus, time, ?DEFAULT_LIMITER_TIME_WINDOW}
    ].

task_poller_pool_size(activity) -> 10;
task_poller_pool_size(session) -> 2;
task_poller_pool_size(_WorkerType) -> 5.

-spec get_opts(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: temporal_sdk_worker:worker_type(),
    WorkerId :: temporal_sdk_worker:worker_id()
) -> {ok, temporal_sdk_worker:opts()} | temporal_sdk_worker:invalid_error().
get_opts(Cluster, session, WorkerId) ->
    case get_state(Cluster, workflow, WorkerId) of
        % eqwalizer:ignore
        {ok, {#{task_settings := #{session_worker := SW}}, _LimiterCounter}} -> {ok, SW};
        {ok, {#{}, _LimiterCounter}} -> {error, invalid_worker};
        Err -> Err
    end;
get_opts(Cluster, WorkerType, WorkerId) ->
    case get_state(Cluster, WorkerType, WorkerId) of
        {ok, {Opts, _LimiterCounter}} -> {ok, Opts};
        Err -> Err
    end.

-spec stats(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: temporal_sdk_worker:worker_type(),
    WorkerId :: temporal_sdk_worker:worker_id()
) -> {ok, temporal_sdk_limiter:stats()} | temporal_sdk_worker:invalid_error().
stats(Cluster, session, WorkerId) ->
    do_stats(Cluster, workflow, WorkerId, session);
stats(Cluster, WorkerType, WorkerId) ->
    do_stats(Cluster, WorkerType, WorkerId, worker).

do_stats(Cluster, WorkerType, WorkerId, Key) ->
    case get_state(Cluster, WorkerType, WorkerId) of
        {ok, {_Opts, #{Key := LimiterCounter}}} ->
            {ok, temporal_sdk_limiter:get_concurrency(LimiterCounter)};
        {ok, {_Opts, #{}}} ->
            {error, invalid_worker};
        Err ->
            Err
    end.

-spec worker_type_to_limitable(WorkerType :: temporal_sdk_worker:worker_type()) ->
    temporal_sdk_limiter:limitable().
worker_type_to_limitable(activity) -> activity_regular;
worker_type_to_limitable(nexus) -> nexus;
worker_type_to_limitable(session) -> activity_session;
worker_type_to_limitable(workflow) -> workflow.

%% -------------------------------------------------------------------------------------------------
%% gen_server

-spec get_state(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: activity | nexus | workflow,
    WorkerId :: temporal_sdk_worker:worker_id()
) ->
    {ok, {
        Opts :: temporal_sdk_worker:opts(),
        LimiterCounters :: #{
            worker := temporal_sdk_limiter:counter(),
            session => temporal_sdk_limiter:counter()
        }
    }}
    | temporal_sdk_worker:invalid_error().
get_state(Cluster, WorkerType, WorkerId) when WorkerType =:= activity; WorkerType =:= workflow ->
    case temporal_sdk_cluster:is_alive(Cluster) of
        true ->
            try
                {ok, gen_server:call(server_name(Cluster, WorkerType, WorkerId), get)}
            catch
                exit:{noproc, _} -> {error, invalid_worker}
            end;
        Err ->
            Err
    end;
get_state(_Cluster, _WorkerType, _WorkerId) ->
    {error, invalid_worker}.

-spec start_link(
    ApiContext :: temporal_sdk_api:context(),
    LimiterCounters :: #{
        worker := temporal_sdk_limiter:counter(),
        session => temporal_sdk_limiter:counter()
    }
) -> gen_server:start_ret().
start_link(ApiContext, LimiterCounters) ->
    #{cluster := Cluster, worker_type := WorkerType, worker_opts := #{worker_id := WorkerId}} =
        ApiContext,
    gen_server:start_link(
        server_name(Cluster, WorkerType, WorkerId),
        ?MODULE,
        [ApiContext, LimiterCounters],
        []
    ).

init([ApiContext, LimiterCounters]) ->
    #{
        cluster := Cluster,
        worker_type := WorkerType,
        worker_opts := #{worker_id := WorkerId} = WorkerOpts
    } =
        ApiContext,
    proc_lib:set_label(
        temporal_sdk_utils_path:string_path([?MODULE, Cluster, WorkerType, WorkerId])
    ),
    {ok, {WorkerOpts, LimiterCounters}}.

handle_call(get, _From, State) ->
    {reply, State, State};
handle_call(_Request, _From, State) ->
    {stop, invalid_request, State}.

handle_cast({set_limits, NewLimits}, {WorkerOpts, LimiterCounters}) ->
    {noreply, {maps:merge(WorkerOpts, NewLimits), LimiterCounters}};
handle_cast({set_session_limits, NewLimits}, {WorkerOpts, LimiterCounters}) ->
    #{task_settings := TS = #{session_worker := SW}} = WorkerOpts,
    {noreply, {
        WorkerOpts#{task_settings := TS#{session_worker := maps:merge(SW, NewLimits)}},
        LimiterCounters
    }};
handle_cast(_Request, State) ->
    {stop, invalid_request, State}.

server_name(Cluster, activity, WorkerId) ->
    {via, temporal_sdk_worker_registry, {Cluster, activity_opts, WorkerId}};
server_name(Cluster, nexus, WorkerId) ->
    {via, temporal_sdk_worker_registry, {Cluster, nexus_opts, WorkerId}};
server_name(Cluster, workflow, WorkerId) ->
    {via, temporal_sdk_worker_registry, {Cluster, workflow_opts, WorkerId}}.
