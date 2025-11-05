-module(temporal_sdk_api_poll).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    poll_activity_task_queue/1,
    poll_nexus_task_queue/1,
    poll_workflow_task_queue/1,
    poll_workflow_task_queue/2,
    shutdown_worker/1
]).

-include("proto.hrl").

-spec poll_activity_task_queue(ApiContext :: temporal_sdk_api:context()) ->
    temporal_sdk_client:msg_result().
poll_activity_task_queue(ApiContext) ->
    #{
        worker_opts := #{
            namespace := Namespace,
            task_queue := TaskQueue,
            worker_version := WorkerVersion
        }
    } = ApiContext,
    Msg =
        temporal_sdk_api:put_identity(
            ApiContext,
            'temporal.api.workflowservice.v1.PollActivityTaskQueueRequest',
            #{
                namespace => Namespace,
                task_queue => #{name => TaskQueue, kind => 'TASK_QUEUE_KIND_NORMAL'},
                % TODO: consider adding task_queue_metadata => #{max_tasks_per_second => ...},
                worker_version_capabilities => WorkerVersion
            }
        ),
    temporal_sdk_api:request('PollActivityTaskQueue', ApiContext, Msg, msg).

-spec poll_nexus_task_queue(ApiContext :: temporal_sdk_api:context()) ->
    temporal_sdk_client:msg_result().
poll_nexus_task_queue(ApiContext) ->
    #{
        worker_opts := #{
            namespace := Namespace,
            task_queue := TaskQueue,
            worker_version := WorkerVersion
        }
    } = ApiContext,
    Msg =
        temporal_sdk_api:put_identity(
            ApiContext,
            'temporal.api.workflowservice.v1.PollNexusTaskQueueRequest',
            #{
                namespace => Namespace,
                task_queue => #{name => TaskQueue, kind => 'TASK_QUEUE_KIND_NORMAL'},
                worker_version_capabilities => WorkerVersion
            }
        ),
    temporal_sdk_api:request('PollNexusTaskQueue', ApiContext, Msg, msg).

-spec poll_workflow_task_queue(ApiContext :: temporal_sdk_api:context()) ->
    temporal_sdk_client:msg_result().
poll_workflow_task_queue(
    #{task_opts := #{sticky_attributes := #{worker_task_queue := StickyTaskQueue}}} = ApiContext
) ->
    poll_workflow_task_queue(ApiContext, StickyTaskQueue).

-spec poll_workflow_task_queue(
    ApiContext :: temporal_sdk_api:context(),
    TaskQueue :: ?TEMPORAL_SPEC:'temporal.api.taskqueue.v1.TaskQueue'()
) -> temporal_sdk_client:msg_result().
poll_workflow_task_queue(ApiContext, TaskQueue) ->
    #{
        worker_opts := #{namespace := Namespace, worker_version := WorkerVersion}
    } = ApiContext,
    Msg =
        temporal_sdk_api:put_identity(
            ApiContext,
            'temporal.api.workflowservice.v1.PollWorkflowTaskQueueRequest',
            #{
                namespace => Namespace,
                task_queue => TaskQueue,
                worker_version_capabilities => WorkerVersion
            }
        ),
    temporal_sdk_api:request('PollWorkflowTaskQueue', ApiContext, Msg, msg).

-spec shutdown_worker(ApiContext :: temporal_sdk_api:context()) ->
    temporal_sdk_client:cast_result().
shutdown_worker(ApiContext) ->
    #{
        worker_opts := #{namespace := Namespace},
        task_opts := #{sticky_attributes := #{worker_task_queue := #{name := STQ}}}
    } = ApiContext,
    Msg =
        temporal_sdk_api:put_identity(
            ApiContext,
            'temporal.api.workflowservice.v1.ShutdownWorkerRequest',
            #{namespace => Namespace, sticky_task_queue => STQ, reason => "graceful_shutdown"}
        ),
    temporal_sdk_api:request('ShutdownWorker', ApiContext, Msg, cast).
