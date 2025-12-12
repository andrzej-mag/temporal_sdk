-module(temporal_sdk_scope_pg_cluster_sup).
-behaviour(supervisor).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    start_link/2
]).
-export([
    init/1
]).

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
            start => {pg, start_link, [temporal_sdk_scope:pg_scope_id(Scope, P)]}
        }
     || P <- lists:seq(1, ShardSize)
    ].
