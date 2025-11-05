-module(temporal_sdk_node_telemetry_poller).
-behaviour(temporal_sdk_telemetry_poller).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    poll/2
]).

-define(EVENT_ORIGIN, node).

poll(Metadata, Timeout) ->
    Clusters = temporal_sdk_cluster:list(),
    temporal_sdk_telemetry:spawn_execute(
        [?EVENT_ORIGIN],
        Metadata,
        #{
            clusters_count => length(Clusters),
            clusters_list => Clusters,
            stats => temporal_sdk_node:stats(),
            os_stats => temporal_sdk_node:os_stats()
        },
        Timeout
    ).
