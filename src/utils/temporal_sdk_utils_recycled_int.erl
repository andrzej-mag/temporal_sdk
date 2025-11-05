-module(temporal_sdk_utils_recycled_int).
-behaviour(gen_server).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    new/1,
    recycle/1
]).
-export([
    start_link/2
]).
-export([
    init/1,
    handle_cast/2,
    handle_info/2,
    handle_call/3
]).

-record(state, {
    msg_tag :: term(),
    recycled = [] :: [pos_integer()],
    reserved = #{} :: #{pid() => pos_integer()}
}).

%% -------------------------------------------------------------------------------------------------
%% public

new(LocalName) -> gen_server:cast(LocalName, {new, self()}).
recycle(LocalName) -> gen_server:cast(LocalName, {recycle, self()}).

%% -------------------------------------------------------------------------------------------------
%% gen_server

-spec start_link(LocalName :: atom(), MsgTag :: term()) -> gen_server:start_ret().
start_link(LocalName, MsgTag) ->
    gen_server:start_link({local, LocalName}, ?MODULE, [MsgTag], []).

init([MsgTag]) ->
    {ok, #state{msg_tag = MsgTag}}.

handle_cast({new, FromPid}, #state{recycled = [Int | Recycled], reserved = Reserved} = State) ->
    handle_new(FromPid, Int, Recycled, Reserved, State);
handle_cast({new, FromPid}, #state{recycled = [], reserved = Reserved} = State) ->
    Int = map_size(Reserved) + 1,
    handle_new(FromPid, Int, [], Reserved, State);
handle_cast({recycle, FromPid}, State) ->
    handle_recycle(FromPid, State).

handle_info({'DOWN', _MonitorRef, process, FromPid, _Reason}, State) ->
    handle_recycle(FromPid, State).

handle_call(Request, FromPid, State) ->
    erlang:error("Invalid request.", [Request, FromPid, State]).

handle_new(FromPid, Int, Recycled, Reserved, #state{msg_tag = MsgTag} = State) ->
    case maps:is_key(FromPid, Reserved) of
        false ->
            FromPid ! {MsgTag, {recycled_integer, Int}},
            monitor(process, FromPid),
            {noreply, State#state{recycled = Recycled, reserved = Reserved#{FromPid => Int}}};
        true ->
            {stop, "Duplicate <new> request.", State}
    end.

handle_recycle(FromPid, State) ->
    case maps:take(FromPid, State#state.reserved) of
        {Int, Reserved} ->
            {noreply, State#state{recycled = [Int | State#state.recycled], reserved = Reserved}};
        error ->
            {noreply, State}
    end.
