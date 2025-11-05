-module(temporal_sdk_poller_adapter).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    handle_poll/1,
    handle_execute/2
]).

-callback handle_poll(ApiContext :: temporal_sdk_api:context()) ->
    temporal_sdk_client:msg_result().

-callback handle_execute(
    ApiContext :: temporal_sdk_api:context(),
    Task :: temporal_sdk_activity:task() | temporal_sdk_workflow:task()
) -> {ok, Status :: executed | redirected} | {error, Reason :: term()}.

-spec handle_poll(ApiContext :: temporal_sdk_api:context()) -> temporal_sdk_client:msg_result().
handle_poll(#{worker_type := WorkerType} = ApiContext) ->
    M = get_module(WorkerType),
    M:handle_poll(ApiContext).

-spec handle_execute(
    ApiContext :: temporal_sdk_api:context(),
    Task :: temporal_sdk_activity:task() | temporal_sdk_workflow:task()
) -> {ok, Status :: executed | redirected} | {error, Reason :: term()}.
handle_execute(#{worker_type := WorkerType} = ApiContext, Task) ->
    M = get_module(WorkerType),
    M:handle_execute(ApiContext, Task).

get_module(activity) -> temporal_sdk_poller_adapter_activity_task_queue;
get_module(nexus) -> temporal_sdk_poller_adapter_nexus_task_queue;
get_module(session) -> temporal_sdk_poller_adapter_activity_task_queue;
get_module(workflow) -> temporal_sdk_poller_adapter_workflow_task_queue.
