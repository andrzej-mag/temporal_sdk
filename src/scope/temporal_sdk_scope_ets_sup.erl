-module(temporal_sdk_scope_ets_sup).
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
    {ok, {#{strategy => one_for_one}, child_spec(ScopeConfig)}}.

child_spec(ScopeConfig) ->
    [
        #{
            id => {temporal_sdk_scope_ets_cluster_sup, Scope},
            start => {temporal_sdk_scope_ets_cluster_sup, start_link, [Scope, Partitions]},
            type => supervisor
        }
     || {Scope, Partitions} <- ScopeConfig
    ].
