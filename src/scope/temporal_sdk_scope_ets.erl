-module(temporal_sdk_scope_ets).
-behaviour(gen_server).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    new/1
]).
-export([
    start_link/2
]).
-export([
    init/1,
    handle_cast/2,
    handle_call/3
]).

%% -------------------------------------------------------------------------------------------------
%% public

new(EtsScopeId) ->
    gen_server:cast(EtsScopeId, {new, self()}).

%% -------------------------------------------------------------------------------------------------
%% gen_server

-spec start_link(Scope :: temporal_sdk_cluster:cluster_name(), Partition :: pos_integer()) ->
    gen_server:start_ret().
start_link(Scope, Partition) ->
    gen_server:start_link(
        {local, temporal_sdk_scope:ets_scope_id(Scope, Partition)},
        ?MODULE,
        [Scope],
        []
    ).

init([_Scope]) ->
    {ok, []}.

handle_cast({new, From}, State) when is_pid(From) ->
    From ! {new_integer, abs(erlang:monotonic_time(second))},
    {noreply, State}.

handle_call(Request, From, State) ->
    erlang:error("Invalid gen_server call.", [Request, From, State]).
