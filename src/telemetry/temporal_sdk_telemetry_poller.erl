-module(temporal_sdk_telemetry_poller).
-behaviour(gen_server).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    start_link/4
]).
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2
]).

-callback poll(Metadata :: telemetry:event_metadata(), Timeout :: integer()) -> ok.

-record(state, {
    interval :: pos_integer(),
    poller_mod :: module(),
    metadata :: telemetry:event_metadata(),
    timeout :: pos_integer()
}).

-spec start_link(
    PollerId :: atom() | string(),
    Interval :: pos_integer(),
    PollerMod :: module(),
    Metadata :: telemetry:event_metadata()
) ->
    gen_server:start_ret().
start_link(PollerId, Interval, PollerMod, Metadata) when is_atom(PollerId) ->
    gen_server:start_link(
        {local, temporal_sdk_utils_path:atom_path([?MODULE, PollerId])},
        ?MODULE,
        [PollerId, Interval, PollerMod, Metadata],
        []
    );
start_link(PollerId, Interval, PollerMod, Metadata) ->
    gen_server:start_link(
        ?MODULE,
        [PollerId, Interval, PollerMod, Metadata],
        []
    ).

init([PollerId, Interval, PollerMod, Metadata]) when is_atom(PollerId) ->
    init(Interval, PollerMod, Metadata);
init([PollerId, Interval, PollerMod, Metadata]) ->
    ProcLabel = temporal_sdk_utils_path:string_path([?MODULE, PollerId]),
    proc_lib:set_label(ProcLabel),
    init(Interval, PollerMod, Metadata).

init(Interval, PollerMod, Metadata) ->
    {ok,
        #state{
            interval = Interval,
            poller_mod = PollerMod,
            metadata = Metadata,
            timeout = round(0.8 * Interval)
        },
        jitter(Interval)}.

handle_info(timeout, State) ->
    #state{interval = Interval, poller_mod = PollerMod, metadata = Metadata, timeout = Timeout} =
        State,
    PollerMod:poll(Metadata, Timeout),
    {noreply, State, jitter(Interval)};
handle_info(_Info, State) ->
    {stop, invalid_request, State}.

handle_call(_Request, _From, State) ->
    {stop, invalid_request, State}.

handle_cast(_Request, State) ->
    {stop, invalid_request, State}.

jitter(Interval) -> Interval + rand:uniform(10).
