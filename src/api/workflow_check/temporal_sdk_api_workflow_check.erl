-module(temporal_sdk_api_workflow_check).

% elp:ignore W0012 W0040 E1599
-moduledoc {file, "../../../docs/api/workflow_check/temporal_sdk_api_workflow_check/-module.md"}.

-export([
    is_deterministic/5
]).

-include("proto.hrl").

-doc {file,
    % elp:ignore E1599
    "../../../docs/api/workflow_check/temporal_sdk_api_workflow_check/is_deterministic-4.md"}.
-callback is_deterministic(
    ActualAwaitable :: temporal_sdk_workflow:awaitable_temporal_index(),
    ReplayedAwaitable :: temporal_sdk_workflow:awaitable_temporal_index(),
    ActualCommand :: ?TEMPORAL_SPEC:'temporal.api.command.v1.Command'(),
    ReplayedHistoryEvent :: temporal_sdk_workflow:history_event()
) -> boolean().

-doc false.
-spec is_deterministic(
    Module :: module(),
    ActualAwaitable :: temporal_sdk_workflow:awaitable_temporal_index(),
    ReplayedAwaitable :: temporal_sdk_workflow:awaitable_temporal_index(),
    ActualCommand :: ?TEMPORAL_SPEC:'temporal.api.command.v1.Command'(),
    ReplayedHistoryEvent :: temporal_sdk_workflow:history_event()
) -> boolean().
is_deterministic(
    Module, ActualAwaitable, ReplayedAwaitable, ActualCommand, ReplayedHistoryEvent
) ->
    Module:is_deterministic(
        ActualAwaitable, ReplayedAwaitable, ActualCommand, ReplayedHistoryEvent
    ).
