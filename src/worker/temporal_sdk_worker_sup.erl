-module(temporal_sdk_worker_sup).
-behaviour(supervisor).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    start_link/5
]).
-export([
    init/1
]).

-spec start_link(
    ApiContext :: temporal_sdk_api:context(),
    LimiterCounters :: temporal_sdk_limiter:counters(),
    WorkerLimiterCounter :: temporal_sdk_limiter:counter(),
    WorkerLimiterChiSpec :: [supervisor:child_spec()],
    WorkerOpts :: temporal_sdk_worker:opts()
) -> supervisor:startlink_ret().
start_link(
    #{cluster := Cluster, worker_type := WorkerType} = ApiContext,
    LimiterCounters,
    WorkerLimiterCounter,
    WorkerLimiterChiSpec,
    #{worker_id := WorkerId} = WorkerOpts
) ->
    supervisor:start_link(
        {via, temporal_sdk_worker_registry, {Cluster, WorkerType, WorkerId}}, ?MODULE, [
            ApiContext#{worker_opts => WorkerOpts},
            LimiterCounters,
            WorkerLimiterCounter,
            WorkerLimiterChiSpec
        ]
    ).

init([
    ApiContext,
    LimiterCounters,
    WorkerLimiterCounter,
    WorkerLimiterChiSpec
]) ->
    #{
        cluster := Cluster,
        worker_type := WorkerType,
        worker_opts := #{worker_id := WorkerId} = WorkerOpts
    } = ApiContext,
    proc_lib:set_label(
        temporal_sdk_utils_path:string_path([?MODULE, Cluster, WorkerType, WorkerId])
    ),
    ChildSpecs =
        child_specs(ApiContext, LimiterCounters, WorkerLimiterCounter) ++ WorkerLimiterChiSpec,
    temporal_sdk_telemetry:execute([worker, start], #{
        cluster => Cluster, worker_type => WorkerType, opts => WorkerOpts
    }),
    {ok, {#{strategy => one_for_one}, ChildSpecs}}.

child_specs(
    #{worker_opts := #{task_settings := #{session_worker := SW = #{}}}} = ApiContext0,
    LimiterCounters,
    #{worker := WLC, session := SLC} = LC
) ->
    #{cluster := Cluster, worker_type := WorkerType = workflow, worker_opts := WorkerOpts} =
        ApiContext0,
    #{worker_id := WorkerId, telemetry_poll_interval := TelemetryPollInterval} = WorkerOpts,
    #{worker_id := SWorkerId} = SW,
    ApiContext = add_sticky_execution_name(ApiContext0),
    WLCounters = LimiterCounters#{worker => WLC},
    SLCounters = LimiterCounters#{worker => SLC},
    SessionApiContext = ApiContext#{worker_opts := SW, worker_type := session},

    StickyChi =
        case WorkerOpts of
            #{task_settings := #{sticky_execution := #{type := pool}}} ->
                StickyApiContext = ApiContext#{worker_type := sticky_queue},
                [
                    #{
                        id => {temporal_sdk_poller_sup, Cluster, sticky_queue, WorkerId},
                        start =>
                            {temporal_sdk_poller_sup, start_link, [
                                temporal_sdk_api_context:add_limiter_counters(
                                    StickyApiContext, WorkerType, WLCounters
                                ),
                                WLCounters,
                                self()
                            ]},
                        type => supervisor,
                        restart => transient
                    }
                ];
            #{task_settings := #{sticky_execution := #{type := _}}} ->
                []
        end,

    [
        #{
            id => {temporal_sdk_telemetry_poller, Cluster, WorkerType, WorkerId},
            start =>
                {temporal_sdk_telemetry_poller, start_link, [
                    temporal_sdk_utils_path:string_path([Cluster, WorkerType, WorkerId]),
                    TelemetryPollInterval,
                    temporal_sdk_worker_telemetry_poller,
                    #{cluster => Cluster, worker_type => WorkerType, worker_id => WorkerId}
                ]},
            restart => transient
        },
        #{
            id => {temporal_sdk_telemetry_poller, Cluster, session, WorkerId},
            start =>
                {temporal_sdk_telemetry_poller, start_link, [
                    temporal_sdk_utils_path:string_path([Cluster, session, WorkerId]),
                    TelemetryPollInterval,
                    temporal_sdk_worker_session_telemetry_poller,
                    #{cluster => Cluster, worker_type => session, worker_id => SWorkerId}
                ]},
            restart => transient
        },
        #{
            id => {temporal_sdk_poller_sup, Cluster, WorkerType, WorkerId},
            start =>
                {temporal_sdk_poller_sup, start_link, [
                    temporal_sdk_api_context:add_limiter_counters(
                        ApiContext, WorkerType, WLCounters
                    ),
                    WLCounters,
                    self()
                ]},
            type => supervisor,
            restart => transient
        },
        #{
            id => {temporal_sdk_poller_sup, Cluster, session, WorkerId},
            start =>
                {temporal_sdk_poller_sup, start_link, [
                    temporal_sdk_api_context:add_limiter_counters(
                        SessionApiContext, session, SLCounters
                    ),
                    SLCounters,
                    self()
                ]},
            type => supervisor,
            restart => transient
        },
        #{
            id => {temporal_sdk_worker_opts, Cluster, WorkerType, WorkerId},
            start => {temporal_sdk_worker_opts, start_link, [ApiContext, LC]},
            restart => transient
        }
    ] ++ StickyChi;
child_specs(ApiContext, LimiterCounters, #{worker := WLC} = LC) ->
    #{
        cluster := Cluster,
        worker_type := WorkerType,
        worker_opts := #{worker_id := WorkerId, telemetry_poll_interval := TelemetryPollInterval}
    } =
        ApiContext,
    WLCounters = LimiterCounters#{worker => WLC},
    [
        #{
            id => {temporal_sdk_telemetry_poller, Cluster, WorkerType, WorkerId},
            start =>
                {temporal_sdk_telemetry_poller, start_link, [
                    temporal_sdk_utils_path:string_path([Cluster, WorkerType, WorkerId]),
                    TelemetryPollInterval,
                    temporal_sdk_worker_telemetry_poller,
                    #{cluster => Cluster, worker_type => WorkerType, worker_id => WorkerId}
                ]},
            restart => transient
        },
        #{
            id => {temporal_sdk_poller_sup, Cluster, WorkerType, WorkerId},
            start =>
                {temporal_sdk_poller_sup, start_link, [
                    temporal_sdk_api_context:add_limiter_counters(
                        ApiContext, WorkerType, WLCounters
                    ),
                    WLCounters,
                    self()
                ]},
            type => supervisor,
            restart => transient
        },
        #{
            id => {temporal_sdk_worker_opts, Cluster, WorkerType, WorkerId},
            start => {temporal_sdk_worker_opts, start_link, [ApiContext, LC]},
            restart => transient
        }
    ].

add_sticky_execution_name(
    #{worker_opts := #{task_settings := #{sticky_execution := #{queue_name := _}}}} = AC
) ->
    AC;
add_sticky_execution_name(
    #{worker_opts := WO = #{task_settings := TS = #{sticky_execution := #{type := pool} = SE}}} = AC
) ->
    StickyName = temporal_sdk_utils_path:string_path([
        node(), pid_to_list(self()), temporal_sdk_utils:uuid4()
    ]),
    AC#{
        worker_opts := WO#{task_settings := TS#{sticky_execution := SE#{queue_name => StickyName}}}
    };
add_sticky_execution_name(#{} = ApiContext) ->
    ApiContext.
