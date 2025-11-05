-module(temporal_sdk_api_nexus).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    respond_nexus_task_completed/3,
    respond_nexus_task_canceled/2,
    respond_nexus_task_failed/2
]).

respond_nexus_task_completed(ApiContext, Task, Result) ->
    MsgName = 'temporal.api.workflowservice.v1.RespondNexusTaskCompletedRequest',
    #{worker_opts := #{namespace := Namespace}, task_opts := #{token := Token}} = ApiContext,
    #{links := Links} = temporal_sdk_api_nexus_task:start_operation(Task),
    Payload = temporal_sdk_api:map_to_payload(
        ApiContext, 'temporal.api.nexus.v1.StartOperationResponse', [sync_success, payload], Result
    ),
    Response = #{
        variant =>
            {start_operation, #{variant => {sync_success, #{payload => Payload, links => Links}}}}
    },
    Msg = temporal_sdk_api:put_identity(ApiContext, MsgName, #{
        namespace => Namespace, task_token => Token, response => Response
    }),
    temporal_sdk_api:request('RespondNexusTaskCompleted', ApiContext, Msg, cast).

respond_nexus_task_canceled(_ApiCtx, _TaskResult) -> ok.

respond_nexus_task_failed(_ApiCtx, _Failure) -> ok.
