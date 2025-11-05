-module(temporal_sdk_api_workflow_check).

% elp:ignore W0012 W0040
-moduledoc """
Workflow determinism check behaviour module.
""".

-export([
    is_deterministic/5
]).

-include("proto.hrl").

-callback is_deterministic(
    ActualAwaitableTask :: temporal_sdk_workflow:awaitable_temporal_index(),
    ReceivedAwaitableTask :: temporal_sdk_workflow:awaitable_temporal_index(),
    ActualCommand :: ?TEMPORAL_SPEC:'temporal.api.command.v1.Command'(),
    ReceivedHistoryEvent :: temporal_sdk_workflow:history_event()
) -> boolean().

-doc false.
-spec is_deterministic(
    Module :: module(),
    ActualAwaitableTask :: temporal_sdk_workflow:awaitable_temporal_index(),
    ReceivedAwaitableTask :: temporal_sdk_workflow:awaitable_temporal_index(),
    ActualCommand :: ?TEMPORAL_SPEC:'temporal.api.command.v1.Command'(),
    ReceivedHistoryEvent :: temporal_sdk_workflow:history_event()
) -> boolean().
is_deterministic(
    Module, ActualAwaitableTask, ReceivedAwaitableTask, ActualCommand, ReceivedHistoryEvent
) ->
    Module:is_deterministic(
        ActualAwaitableTask, ReceivedAwaitableTask, ActualCommand, ReceivedHistoryEvent
    ).
