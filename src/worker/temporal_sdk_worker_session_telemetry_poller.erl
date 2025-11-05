-module(temporal_sdk_worker_session_telemetry_poller).
-behaviour(temporal_sdk_telemetry_poller).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    poll/2
]).

-define(EVENT_ORIGIN, worker).

poll(Metadata, Timeout) ->
    #{cluster := Cluster, worker_id := WorkerId} = Metadata,
    case temporal_sdk_worker:stats(Cluster, session, WorkerId) of
        {ok, S} ->
            temporal_sdk_telemetry:spawn_execute([?EVENT_ORIGIN], Metadata, #{stats => S}, Timeout);
        _Err ->
            ok
    end.
