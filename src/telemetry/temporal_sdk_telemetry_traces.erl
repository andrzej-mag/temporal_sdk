-module(temporal_sdk_telemetry_traces).

% elp:ignore W0012 W0040
-moduledoc """
WIP Telemetry traces module.
""".

-export([
    setup/0,
    setup/1,
    handle_event/4
]).

% -include_lib("opentelemetry_semantic_conventions/include/trace.hrl").

-define(EVENT_NAME_PREFIX, temporal_sdk).

%% Event names are expanded by adding prefix `temporal_sdk` and two suffix variants `stop` and
%% `exception`.
%% For example, [grpc] is mapped to two events:
%% [temporal_sdk, grpc, stop] and [temporal_sdk, grpc, exception].
-define(DEFAULT_EVENTS, [
    [grpc],
    [queue_poll],
    [activity],
    [activity, execute],
    [activity, handle_heartbeat],
    [activity, record_heartbeat],
    [activity, respond_completed],
    [activity, respond_canceled],
    [activity, respond_failed],
    [workflow],
    [poller, poll],
    [poller, execute],
    [poller, wait]
]).

setup() ->
    setup(?DEFAULT_EVENTS).

-spec setup(Events :: [telemetry:event_name()]) -> ok | {error, already_exists}.
setup([]) ->
    ok;
setup(Events) ->
    io:fwrite("            _________ ~p:~p~n", [?MODULE, ?FUNCTION_NAME]),
    telemetry:attach_many(?MODULE, map_events_names(Events), fun ?MODULE:handle_event/4, []).

-spec handle_event(
    EventName :: telemetry:event_name(),
    Measurements :: telemetry:event_measurements() | telemetry:event_value(),
    Metadata :: telemetry:event_metadata(),
    HandlerConfig :: telemetry:handler_config()
) -> term().
handle_event([?EVENT_NAME_PREFIX | TEvent], #{duration := Duration}, Metadata, []) ->
    do_handle_event(TEvent, Metadata, Duration).

do_handle_event([grpc | _TEvent], #{service_info := #{name := Name}}, Duration) ->
    io:fwrite("~p       ~p~n", [Name, Duration]),
    ok;
do_handle_event(Event, _Metadata, Duration) ->
    D = erlang:convert_time_unit(Duration, native, millisecond),
    io:fwrite("~p    ~p~n", [Event, D]),
    % io:fwrite("~p~n", [Metadata]),
    ok.

map_events_names(Events) ->
    lists:foldl(
        fun(E, Acc) when is_list(E), is_list(Acc) ->
            E1 = lists:append([[?EVENT_NAME_PREFIX], E, [stop]]),
            E2 = lists:append([[?EVENT_NAME_PREFIX], E, [exception]]),
            [E1 | [E2 | Acc]]
        end,
        [],
        Events
    ).
