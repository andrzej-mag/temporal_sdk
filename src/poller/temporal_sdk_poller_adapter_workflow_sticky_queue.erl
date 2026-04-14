-module(temporal_sdk_poller_adapter_workflow_sticky_queue).
-behaviour(temporal_sdk_poller_adapter).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    handle_poll/1,
    handle_execute/2,
    handle_shutdown/1
]).

-include("sdk.hrl").

-define(REQUIRED_TASK_KEYS, [
    task_token,
    workflow_execution,
    workflow_type,
    previous_started_event_id,
    started_event_id,
    attempt,
    history,
    next_page_token,
    workflow_execution_task_queue
    %% not present in special poll responses: scheduled_time, started_time
]).

handle_poll(ApiContext) ->
    temporal_sdk_api_poll:poll_workflow_sticky_queue(ApiContext).

handle_execute(ApiContext, Task) ->
    #{cluster := Cluster, worker_opts := WorkerOpts} = ApiContext,
    maybe
        true ?= temporal_sdk_poller_adapter_utils:is_task_valid(Task, ?REQUIRED_TASK_KEYS),
        true ?= has_valid_history(Task),
        #{workflow_type := #{name := TaskName}} = Task,
        {ok, Mod} ?=
            temporal_sdk_poller_adapter_utils:validate_temporal_task_name(
                Cluster, WorkerOpts, TaskName
            ),
        AC = temporal_sdk_scope:init_ctx(
            temporal_sdk_api_context:add_workflow_opts(ApiContext, Task, Mod)
        ),
        do_handle_execute(temporal_sdk_scope:get_local_members(AC), Task)
    end.

handle_shutdown(ApiContext) -> temporal_sdk_api_poll:shutdown_worker(ApiContext).

has_valid_history(#{history := #{events := [#{event_id := _, attributes := {_, #{}}} | _]}}) ->
    true;
has_valid_history(#{history := #{events := []}, started_event_id := 0}) ->
    true;
has_valid_history(Invalid) ->
    {error, #{
        reason => "Unhandled workflow sticky task: missing or invalid events history.",
        invalid_task => Invalid
    }}.

do_handle_execute([], _Task) ->
    {ok, evicted};
do_handle_execute(Pids, Task) ->
    [P ! {?TEMPORAL_SDK_GRPC_TAG, sticky_queue, {ok, Task}} || P <- Pids],
    {ok, redirected}.
