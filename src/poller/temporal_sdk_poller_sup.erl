-module(temporal_sdk_poller_sup).
-behaviour(supervisor).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    start_link/3
]).
-export([
    init/1
]).

-spec start_link(
    ApiContext :: temporal_sdk_api:context(),
    LimiterCounters :: temporal_sdk_limiter:counters(),
    WorkerSupPid :: pid()
) -> supervisor:startlink_ret().
start_link(ApiContext, LimiterCounters, WorkerSupPid) ->
    supervisor:start_link(?MODULE, [ApiContext, LimiterCounters, WorkerSupPid]).

init([ApiContext, LimiterCounters, WorkerSupPid]) ->
    #{cluster := Cluster, worker_type := WorkerType, worker_opts := #{worker_id := WorkerId}} =
        ApiContext,
    ProcLabel = temporal_sdk_utils_path:string_path([?MODULE, Cluster, WorkerType, WorkerId]),
    proc_lib:set_label(ProcLabel),
    ChildSpecs = child_specs(ApiContext, LimiterCounters, WorkerSupPid),
    {ok, {#{strategy => one_for_one}, ChildSpecs}}.

child_specs(
    #{worker_opts := #{task_poller_pool_size := Size}} = ApiContext,
    LimiterCounters,
    WorkerSupPid
) when is_integer(Size), Size > 0 ->
    #{cluster := Cluster, worker_type := WorkerType, worker_opts := #{worker_id := WorkerId}} =
        ApiContext,
    PollCounter = counters:new(1, [write_concurrency]),
    [
        #{
            id => {temporal_sdk_poller, Cluster, WorkerType, WorkerId, I},
            start =>
                {temporal_sdk_poller, start_link, [
                    add_sticky_attributes(ApiContext, I),
                    LimiterCounters,
                    PollCounter,
                    WorkerSupPid,
                    I
                ]},
            restart => transient
        }
     || I <- lists:seq(1, Size)
    ];
child_specs(_ApiContext, _Limiters, _WorkerSupPid) ->
    [].

add_sticky_attributes(
    #{
        worker_type := sticky_queue,
        worker_opts := #{
            task_queue := TQ,
            task_settings := #{sticky_execution := #{type := pool, queue_name := N} = SE}
        }
    } = ApiCtx,
    I
) ->
    StickyName = temporal_sdk_utils_path:string_path([N, I]),
    WTQ = #{name => StickyName, kind => 'TASK_QUEUE_KIND_STICKY', normal_name => TQ},
    SA =
        case SE of
            #{schedule_to_start_timeout := STST} ->
                {pool, #{worker_task_queue => WTQ, schedule_to_start_timeout => STST}};
            #{} ->
                {pool, #{worker_task_queue => WTQ}}
        end,
    ApiCtx#{task_opts => #{sticky_attributes => SA}};
add_sticky_attributes(ApiCtx, _I) ->
    ApiCtx.
