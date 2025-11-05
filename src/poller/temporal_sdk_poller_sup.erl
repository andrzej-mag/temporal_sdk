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
                    ApiContext, LimiterCounters, PollCounter, WorkerSupPid, I
                ]},
            restart => transient
        }
     || I <- lists:seq(1, Size)
    ];
child_specs(_ApiContext, _Limiters, _WorkerSupPid) ->
    [].
