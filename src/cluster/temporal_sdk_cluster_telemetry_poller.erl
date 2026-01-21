-module(temporal_sdk_cluster_telemetry_poller).
-behaviour(temporal_sdk_telemetry_poller).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    poll/2
]).

-define(EVENT_ORIGIN, [cluster, stats]).

poll(#{cluster := Cluster} = Metadata, Timeout) ->
    {AW, AWCount} = parse_worker_list(Cluster, activity),
    {NW, NWCount} = parse_worker_list(Cluster, nexus),
    {WW, WWCount} = parse_worker_list(Cluster, workflow),
    {ok, Stats} = temporal_sdk_cluster:stats(Cluster),
    temporal_sdk_telemetry:spawn_execute(
        ?EVENT_ORIGIN,
        Metadata,
        #{
            activity_list => AW,
            activity_count => AWCount,
            nexus_list => NW,
            nexus_count => NWCount,
            workflow_list => WW,
            workflow_count => WWCount,
            stats => Stats
        },
        Timeout
    ).

parse_worker_list(Cluster, WorkerType) ->
    case temporal_sdk_worker:list(Cluster, WorkerType) of
        {ok, W} -> {W, length(W)};
        _ -> {null, null}
    end.
