-module(temporal_sdk_scope_sup).
-behaviour(supervisor).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    start_link/1
]).
-export([
    init/1
]).

-spec start_link(ScopeConfig :: [temporal_sdk_node:scope_config()]) -> supervisor:startlink_ret().
start_link(ScopeConfig) ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, [ScopeConfig]).

init([ScopeConfig]) ->
    {ok,
        {#{strategy => one_for_one}, [
            #{
                id => temporal_sdk_scope_pg_sup,
                start => {temporal_sdk_scope_pg_sup, start_link, [ScopeConfig]},
                type => supervisor
            },
            #{
                id => temporal_sdk_scope_ets_sup,
                start => {temporal_sdk_scope_ets_sup, start_link, [ScopeConfig]},
                type => supervisor
            }
        ]}}.
