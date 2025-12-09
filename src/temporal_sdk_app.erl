-module(temporal_sdk_app).
-behaviour(application).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    start/2,
    stop/1
]).

start(_StartType, _StartArgs) ->
    case temporal_sdk_node_sup:start_link() of
        {ok, Pid} ->
            temporal_sdk_worker_manager_sup:start_config_workers(),
            {ok, Pid};
        ignore ->
            {error, "Temporal SDK Node init failure. Check temporal_sdk configuration for errors."};
        {error, _} = Err ->
            Err
    end.

stop(_State) ->
    ok.
