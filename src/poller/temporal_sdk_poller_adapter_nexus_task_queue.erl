-module(temporal_sdk_poller_adapter_nexus_task_queue).
-behaviour(temporal_sdk_poller_adapter).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    handle_poll/1,
    handle_execute/2
]).

-define(REQUIRED_TASK_KEYS, [
    task_token,
    request
]).
-define(REQUIRED_REQUEST_KEYS, [
    service,
    operation
]).

handle_poll(ApiContext) -> temporal_sdk_api_poll:poll_nexus_task_queue(ApiContext).

handle_execute(ApiContext, Task) ->
    #{cluster := Cluster, worker_opts := WorkerOpts} = ApiContext,
    maybe
        true ?= temporal_sdk_poller_adapter_utils:is_task_valid(Task, ?REQUIRED_TASK_KEYS),
        StartOperation = temporal_sdk_api_nexus_task:start_operation(Task),
        true ?=
            temporal_sdk_poller_adapter_utils:is_task_valid(StartOperation, ?REQUIRED_REQUEST_KEYS),
        #{service := Service} = StartOperation,
        {ok, Mod} ?=
            temporal_sdk_poller_adapter_utils:validate_temporal_task_name(
                Cluster, WorkerOpts, Service
            ),
        AC = temporal_sdk_api_context:add_nexus_task_opts(ApiContext, Task),
        {ok, _Pid} ?= temporal_sdk_executor_nexus:start(AC, Task, Mod),
        {ok, executed}
    else
        ignore -> {error, activity_executor_start_ignored};
        Err -> Err
    end.
