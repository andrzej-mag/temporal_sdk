-module(temporal_sdk_poller_adapter_activity_task_queue).
-behaviour(temporal_sdk_poller_adapter).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    handle_poll/1,
    handle_execute/2
]).

-define(REQUIRED_TASK_KEYS, [
    task_token,
    workflow_namespace,
    workflow_type,
    workflow_execution,
    activity_type,
    activity_id,
    header,
    scheduled_time,
    started_time,
    attempt
]).

handle_poll(ApiContext) -> temporal_sdk_api_poll:poll_activity_task_queue(ApiContext).

handle_execute(ApiContext, Task) ->
    #{cluster := Cluster, worker_opts := WorkerOpts} = ApiContext,
    maybe
        true ?= temporal_sdk_poller_adapter_utils:is_task_valid(Task, ?REQUIRED_TASK_KEYS),
        #{activity_type := #{name := TaskName}} = Task,
        {ok, Mod} ?=
            temporal_sdk_poller_adapter_utils:validate_temporal_task_name(
                Cluster, WorkerOpts, TaskName
            ),
        AC = temporal_sdk_api_context:add_activity_opts(ApiContext, Task, Mod),
        {ok, _Pid} ?= temporal_sdk_executor_activity:start(AC, Task),
        {ok, executed}
    end.
