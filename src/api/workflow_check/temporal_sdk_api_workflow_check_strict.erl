-module(temporal_sdk_api_workflow_check_strict).
-behaviour(temporal_sdk_api_workflow_check).

% elp:ignore W0012 W0040
-moduledoc """
Strict workflow deterministic checks implementation of `m:temporal_sdk_api_workflow_check` behaviour.
""".

-export([
    is_deterministic/4
]).

-doc false.
is_deterministic(
    {Awaitable, #{event_id := EventId, state := ActualState}},
    {Awaitable, #{event_id := EventId, state := ReceivedState}},
    _ActualCommand,
    _ReceivedHistoryEvent
) ->
    test_state(ActualState, ReceivedState);
is_deterministic(_ActualAwaitable, _ReceivedAwaitable, _ActualCommand, _ReceivedHistoryEvent) ->
    false.

test_state(cmd, _State) -> true;
test_state(State, State) -> true;
test_state(started, canceled) -> true;
test_state(_ActualState, _ReceivedState) -> false.
