-module(temporal_sdk_api_workflow_check_temporal).
-behaviour(temporal_sdk_api_workflow_check).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    is_deterministic/4
]).

-doc false.
is_deterministic(
    {ActualAwaitable, #{event_id := EventId, state := ActualState}},
    {ReceivedAwaitable, #{event_id := EventId, state := ReceivedState}},
    _ActualCommand,
    _ReceivedHistoryEvent
) ->
    test_state(ActualState, ReceivedState) andalso
        test_awaitable(ActualAwaitable, ReceivedAwaitable);
is_deterministic(_ActualAwaitable, _ReceivedAwaitable, _ActualCommand, _ReceivedHistoryEvent) ->
    false.

test_state(cmd, _State) -> true;
test_state(started, canceled) -> true;
test_state(State, State) -> true;
test_state(_ActualState, _ReceivedState) -> false.

test_awaitable({A}, {A}) -> true;
test_awaitable({A, _}, {A, _}) -> true;
test_awaitable({A, _, _}, {A, _, _}) -> true;
test_awaitable(_ActualAwaitable, _ReceivedAwaitable) -> false.
