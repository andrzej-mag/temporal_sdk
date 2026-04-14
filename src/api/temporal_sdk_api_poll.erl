-module(temporal_sdk_api_poll).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    poll_activity_task_queue/1,
    poll_nexus_task_queue/1,
    poll_workflow_task_queue/1,
    poll_workflow_sticky_queue/1,
    shutdown_worker/1
]).

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
poll_workflow_task_queue(ApiContext) ->
    #{
        worker_opts := #{
            task_queue := Name, namespace := Namespace, worker_version := WorkerVersion
        }
    } = ApiContext,
    Msg =
        temporal_sdk_api:put_identity(
            ApiContext,
            'temporal.api.workflowservice.v1.PollWorkflowTaskQueueRequest',
            #{
                namespace => Namespace,
                task_queue => #{name => Name, kind => 'TASK_QUEUE_KIND_NORMAL'},
                worker_version_capabilities => WorkerVersion
            }
        ),
    temporal_sdk_api:request('PollWorkflowTaskQueue', ApiContext, Msg, msg).

-spec poll_workflow_sticky_queue(ApiContext :: temporal_sdk_api:context()) ->
    temporal_sdk_client:msg_result().
poll_workflow_sticky_queue(#{task_opts := #{sticky_attributes := {_, SA}}} = ApiContext) ->
    #{worker_opts := #{namespace := Namespace, worker_version := WorkerVersion}} = ApiContext,
    #{worker_task_queue := StickyTaskQueue} = SA,
    Msg =
        temporal_sdk_api:put_identity(
            ApiContext,
            'temporal.api.workflowservice.v1.PollWorkflowTaskQueueRequest',
            #{
                namespace => Namespace,
                task_queue => StickyTaskQueue,
                worker_version_capabilities => WorkerVersion
            }
        ),
    temporal_sdk_api:request('PollWorkflowTaskQueue', ApiContext, Msg, msg).

-spec shutdown_worker(ApiContext :: temporal_sdk_api:context()) ->
    temporal_sdk_client:cast_result().
shutdown_worker(ApiContext) ->
    #{
        worker_opts := #{namespace := Namespace},
        task_opts := #{sticky_attributes := {Type, #{worker_task_queue := #{name := Name}}}}
    } = ApiContext,
    Reason =
        case Type of
            local -> "executor shutdown";
            pool -> "worker shutdown"
        end,
    Msg =
        temporal_sdk_api:put_identity(
            ApiContext,
            'temporal.api.workflowservice.v1.ShutdownWorkerRequest',
            #{
                namespace => Namespace,
                sticky_task_queue => Name,
                reason => Reason
            }
        ),
    temporal_sdk_api:request('ShutdownWorker', ApiContext, Msg, cast).
