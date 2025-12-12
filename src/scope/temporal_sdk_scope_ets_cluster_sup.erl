-module(temporal_sdk_scope_ets_cluster_sup).
-behaviour(supervisor).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    start_link/2
]).
-export([
    init/1
]).

-include("../executor/temporal_sdk_executor.hrl").

-spec start_link(
    Scope :: temporal_sdk_cluster:cluster_name(), ShardSize :: pos_integer()
) -> supervisor:startlink_ret().
start_link(Scope, ShardSize) ->
    supervisor:start_link(
        {local, temporal_sdk_utils_path:atom_path([?MODULE, Scope])}, ?MODULE, [
            Scope, ShardSize
        ]
    ).

init([Scope, ShardSize]) ->
    {ok, {#{strategy => one_for_one}, child_spec(Scope, ShardSize)}}.

child_spec(Scope, ShardSize) ->
    [
        #{
            id => {?MODULE, Scope, P},
            start =>
                {temporal_sdk_utils_recycled_int, start_link, [
                    temporal_sdk_scope:ets_scope_id(Scope, P), ?MSG_PRV
                ]}
        }
     || P <- lists:seq(1, ShardSize)
    ].
