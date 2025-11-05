-module(temporal_sdk_poller_adapter_workflow_task_queue).
-behaviour(temporal_sdk_poller_adapter).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    handle_poll/1,
    handle_execute/2
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

handle_poll(#{worker_opts := #{task_queue := TaskQueueName}} = ApiContext) ->
    TaskQueue = #{name => TaskQueueName, kind => 'TASK_QUEUE_KIND_NORMAL'},
    temporal_sdk_api_poll:poll_workflow_task_queue(ApiContext, TaskQueue).

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
        do_handle_execute(temporal_sdk_scope:get_members(AC), AC, Task)
    end.

has_valid_history(#{
    history := #{
        events := [
            #{event_id := 1, attributes := {workflow_execution_started_event_attributes, Attr}} | _
        ]
    }
}) when is_map(Attr) ->
    true;
has_valid_history(Invalid) ->
    {error, #{
        reason => "Unhandled workflow task: missing or invalid events history.",
        invalid_task => Invalid
    }}.

do_handle_execute([], ApiCtx, Task) ->
    case temporal_sdk_executor_workflow:start(ApiCtx, Task, undefined) of
        {ok, _Pid} -> {ok, executed};
        Err -> Err
    end;
do_handle_execute([Pid | TPids], _ApiCtx, Task) ->
    Pid ! {?TEMPORAL_SDK_GRPC_TAG, regular_queue, {ok, Task}},
    [P ! {?TEMPORAL_SDK_GRPC_TAG, duplicate_workflow_execution} || P <- TPids],
    {ok, redirected}.
