-module(temporal_sdk_api_workflow_check_temporal).
-behaviour(temporal_sdk_api_workflow_check).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    is_deterministic/4
]).

is_deterministic(
    {ActualAwaitable, #{event_id := EventId, state := ActualState}},
    {ReplayedAwaitable, #{event_id := EventId, state := ReplayedState}},
    _ActualCommand,
    _ReplayedHistoryEvent
) ->
    test_state(ActualState, ReplayedState) andalso
        test_awaitable(ActualAwaitable, ReplayedAwaitable);
is_deterministic(_ActualAwaitable, _ReplayedAwaitable, _ActualCommand, _ReplayedHistoryEvent) ->
    false.

test_state(cmd, _State) -> true;
test_state(started, canceled) -> true;
test_state(State, State) -> true;
test_state(_ActualState, _ReplayedState) -> false.

test_awaitable({A}, {A}) -> true;
test_awaitable({A, _}, {A, _}) -> true;
test_awaitable({A, _, _}, {A, _, _}) -> true;
test_awaitable(_ActualAwaitable, _ReplayedAwaitable) -> false.
