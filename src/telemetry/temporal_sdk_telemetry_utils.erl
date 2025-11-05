-module(temporal_sdk_telemetry_utils).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    attach_many/4
]).

-define(EVENT_NAME_PREFIX, temporal_sdk).

-spec attach_many(
    Events :: [telemetry:event_name()],
    HandlerId :: telemetry:handler_id(),
    HandleEventFun :: telemetry:handler_function(),
    HandleEventFunConfig :: telemetry:handler_config()
) -> ok.
attach_many([], _HandlerId, _HandleEventFun, _HandleEventFunConfig) ->
    ok;
attach_many(Events, HandlerId, HandleEventFun, HandleEventFunConfig) ->
    ok = telemetry:attach_many(
        HandlerId, map_events_names(Events), HandleEventFun, HandleEventFunConfig
    ).

%% -------------------------------------------------------------------------------------------------
%% private

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
