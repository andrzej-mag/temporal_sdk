-module(temporal_sdk_telemetry_logs).

% elp:ignore W0012 W0040
-moduledoc """
WIP Telemetry logs module.
""".

-export([
    setup/1,
    handle_event/4
]).

-include_lib("kernel/include/logger.hrl").

-define(EVENT_NAME_PREFIX, temporal_sdk).

% -define(IGNORED_LOG_LEVEL, error).
-define(IGNORED_LOG_LEVEL, debug).

-type event_action() :: stop | exception.
-export_type([event_action/0]).

-type log_level() :: logger:level() | false.
-export_type([log_level/0]).

-type opts() :: #{
    events => [telemetry:event_name()], log_levels => #{event_action() => log_level()}
}.
-export_type([opts/0]).

-spec setup(Opts :: opts()) -> ok.
setup(#{events := Events, log_levels := LogLevels}) ->
    temporal_sdk_telemetry_utils:attach_many(
        Events,
        ?MODULE,
        % FIXME
        % eqwalizer:ignore
        fun ?MODULE:handle_event/4,
        LogLevels
    ).

-spec handle_event(
    EventName :: telemetry:event_name(),
    Measurements :: #{duration => integer()},
    Metadata :: telemetry:event_metadata(),
    HandlerConfig :: #{event_action() => log_level()}
) -> term().
handle_event([?EVENT_NAME_PREFIX | TEvent] = Event, #{duration := Duration}, Metadata, LogLevels) ->
    do_handle_event(lists:reverse(TEvent), Event, Metadata, Duration, LogLevels).

%% -------------------------------------------------------------------------------------------------
%% private

do_handle_event([stop | _], Event, Metadata, Duration, #{stop := LogLevel}) ->
    maybe_log(LogLevel, Event, Metadata, Duration);
do_handle_event([exception | _], Event, Metadata, Duration, #{exception := LogLevel}) ->
    maybe_log(LogLevel, Event, Metadata, Duration).

maybe_log(false, _Event, _Metadata, _Duration) ->
    ok;
maybe_log(Level, Event, Metadata, Duration) ->
    L =
        case is_ignored(Metadata) of
            true -> ?IGNORED_LOG_LEVEL;
            false -> Level
        end,
    ?LOG(L, Metadata#{
        duration => erlang:convert_time_unit(Duration, native, millisecond), event => Event
    }).

is_ignored(#{reason := #{grpc_response_headers := Headers}, class := error}) ->
    case proplists:get_value(~"grpc-message", Headers, undefined) of
        ~"Workflow task not found." -> true;
        _ -> false
    end;
is_ignored(#{reason := task_token_race_condition, class := error}) ->
    true;
is_ignored(_Metadata) ->
    false.
