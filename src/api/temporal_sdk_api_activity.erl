-module(temporal_sdk_api_activity).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    record_activity_task_heartbeat/2,
    respond_activity_task_completed/2,
    respond_activity_task_failed/3,
    respond_activity_task_canceled/2
]).

-spec record_activity_task_heartbeat(
    ApiContext :: temporal_sdk_api:context(), Details :: temporal_sdk:term_to_payloads()
) -> temporal_sdk_client:msg_result().
record_activity_task_heartbeat(ApiContext, Details) ->
    #{
        worker_opts := #{namespace := Namespace},
        task_opts := #{token := Token}
    } = ApiContext,
    MsgName = 'temporal.api.workflowservice.v1.RecordActivityTaskHeartbeatRequest',
    Msg = temporal_sdk_api:put_identity(ApiContext, MsgName, #{
        namespace => Namespace,
        task_token => Token,
        details => temporal_sdk_api:map_to_payloads(ApiContext, MsgName, details, Details)
    }),
    temporal_sdk_api:request('RecordActivityTaskHeartbeat', ApiContext, Msg, msg).

%% record_activity_task_heartbeat_by_id/4,

-spec respond_activity_task_completed(
    ApiContext :: temporal_sdk_api:context(), Result :: temporal_sdk:term_to_payloads()
) -> temporal_sdk_client:cast_result().
respond_activity_task_completed(ApiContext, Result) ->
    #{
        worker_opts := #{namespace := Namespace, worker_version := WorkerVersion},
        task_opts := #{token := Token}
    } = ApiContext,
    MsgName = 'temporal.api.workflowservice.v1.RespondActivityTaskCompletedRequest',
    Msg = temporal_sdk_api:put_identity(ApiContext, MsgName, #{
        namespace => Namespace,
        task_token => Token,
        worker_version => WorkerVersion,
        result => temporal_sdk_api:map_to_payloads(ApiContext, MsgName, result, Result)
    }),
    temporal_sdk_api:request('RespondActivityTaskCompleted', ApiContext, Msg, cast).

%% respond_activity_task_completed_by_id/4,

-spec respond_activity_task_failed(
    ApiContext :: temporal_sdk_api:context(),
    LastHeartbeatDetails :: temporal_sdk_activity:heartbeat(),
    ApplicationFailure ::
        temporal_sdk:application_failure()
        | temporal_sdk:user_application_failure()
) -> temporal_sdk_client:cast_result().
respond_activity_task_failed(ApiContext, LastHeartbeatDetails, ApplicationFailure) ->
    #{
        worker_opts := #{namespace := Namespace, worker_version := WorkerVersion},
        task_opts := #{token := Token}
    } = ApiContext,
    MsgName = 'temporal.api.workflowservice.v1.RespondActivityTaskFailedRequest',
    case temporal_sdk_api_failure:build(ApiContext, ApplicationFailure) of
        {ok, Failure} ->
            Msg = temporal_sdk_api:put_identity(ApiContext, MsgName, #{
                task_token => Token,
                namespace => Namespace,
                worker_version => WorkerVersion,
                failure => Failure,
                last_heartbeat_details => temporal_sdk_api:map_to_payloads(
                    ApiContext, MsgName, last_heartbeat_details, LastHeartbeatDetails
                )
            }),
            temporal_sdk_api:request('RespondActivityTaskFailed', ApiContext, Msg, cast);
        Err ->
            Err
    end.

%% respond_activity_task_failed_by_id/4,

-spec respond_activity_task_canceled(
    ApiContext :: temporal_sdk_api:context(),
    Details :: temporal_sdk:term_to_payloads()
) -> temporal_sdk_client:cast_result().
respond_activity_task_canceled(ApiContext, Details) ->
    #{
        worker_opts := #{namespace := Namespace, worker_version := WorkerVersion},
        task_opts := #{token := Token}
    } = ApiContext,
    MsgName = 'temporal.api.workflowservice.v1.RespondActivityTaskCanceledRequest',
    Msg = temporal_sdk_api:put_identity(ApiContext, MsgName, #{
        namespace => Namespace,
        task_token => Token,
        worker_version => WorkerVersion,
        details => temporal_sdk_api:map_to_payloads(ApiContext, MsgName, result, Details)
    }),
    temporal_sdk_api:request('RespondActivityTaskCanceled', ApiContext, Msg, cast).

%% respond_activity_task_canceled_by_id/4,
