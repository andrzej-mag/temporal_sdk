-module(temporal_sdk_api_workflow).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    get_workflow_execution_history/2,
    get_workflow_execution_history_reverse/2,
    respond_workflow_task_completed/3,
    respond_workflow_task_failed/3,
    respond_query_task_completed/2,
    reset_workflow_execution/3
]).

-include("proto.hrl").

-spec get_workflow_execution_history(
    ApiContext :: temporal_sdk_api:context(), NextPageToken :: unicode:chardata()
) ->
    temporal_sdk_client:msg_result().
get_workflow_execution_history(ApiContext, NextPageToken) ->
    #{
        worker_opts := #{
            namespace := Namespace, task_settings := #{maximum_page_size := MaximumPageSize}
        },
        task_opts := #{workflow_id := WorkflowId, run_id := RunId}
    } = ApiContext,
    Msg = #{
        namespace => Namespace,
        execution => #{workflow_id => WorkflowId, run_id => RunId},
        next_page_token => NextPageToken,
        maximum_page_size => MaximumPageSize
    },
    temporal_sdk_api:request('GetWorkflowExecutionHistory', ApiContext, Msg, msg).

-spec get_workflow_execution_history_reverse(
    ApiContext :: temporal_sdk_api:context(), MaximumPageSize :: pos_integer()
) -> temporal_sdk_client:msg_result().
get_workflow_execution_history_reverse(ApiContext, MaximumPageSize) ->
    #{
        worker_opts := #{namespace := Namespace},
        task_opts := #{workflow_id := WorkflowId, run_id := RunId}
    } = ApiContext,
    Msg = #{
        namespace => Namespace,
        execution => #{workflow_id => WorkflowId, run_id => RunId},
        maximum_page_size => MaximumPageSize
    },
    temporal_sdk_api:request('GetWorkflowExecutionHistoryReverse', ApiContext, Msg, msg).

-spec respond_workflow_task_completed(
    ApiContext :: temporal_sdk_api:context(),
    Commands :: [?TEMPORAL_SPEC:'temporal.api.command.v1.Command'()],
    Request :: ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.RespondWorkflowTaskCompletedRequest'()
) -> temporal_sdk_client:msg_result() | {error, undefined_task_token}.
respond_workflow_task_completed(#{task_opts := #{token := undefined}}, _Commands, _Request) ->
    {error, undefined_task_token};
respond_workflow_task_completed(
    #{
        worker_opts := #{namespace := Namespace, worker_version := WorkerVersion},
        task_opts := #{token := Token, sticky_attributes := StickyAttributes}
    } = ApiContext,
    Commands,
    Request
) ->
    MsgName = 'temporal.api.workflowservice.v1.RespondWorkflowTaskCompletedRequest',
    Msg = temporal_sdk_api:put_identity(ApiContext, MsgName, Request#{
        task_token => Token,
        commands => Commands,
        namespace => Namespace,
        worker_version_stamp => WorkerVersion,
        return_new_workflow_task => true,
        sticky_attributes => StickyAttributes
    }),
    temporal_sdk_api:request('RespondWorkflowTaskCompleted', ApiContext, Msg, msg).

-spec respond_workflow_task_failed(
    ApiContext :: temporal_sdk_api:context(),
    ApplicationFailure ::
        temporal_sdk:application_failure()
        | temporal_sdk:user_application_failure(),
    FailCause ::
        'WORKFLOW_TASK_FAILED_CAUSE_NON_DETERMINISTIC_ERROR'
        | 'WORKFLOW_TASK_FAILED_CAUSE_WORKFLOW_WORKER_UNHANDLED_FAILURE'
) -> temporal_sdk_client:cast_result().
respond_workflow_task_failed(ApiContext, ApplicationFailure, FailCause) ->
    #{
        worker_opts := #{namespace := Namespace, worker_version := WorkerVersion},
        task_opts := #{token := Token}
    } = ApiContext,
    MsgName = 'temporal.api.workflowservice.v1.RespondWorkflowTaskFailedRequest',
    case temporal_sdk_api_failure:build(ApiContext, ApplicationFailure) of
        {ok, Failure} ->
            Msg = temporal_sdk_api:put_identity(ApiContext, MsgName, #{
                task_token => Token,
                namespace => Namespace,
                worker_version => WorkerVersion,
                cause => FailCause,
                failure => Failure
            }),
            temporal_sdk_api:request('RespondWorkflowTaskFailed', ApiContext, Msg, cast);
        Err ->
            Err
    end.

-spec respond_query_task_completed(
    ApiContext :: temporal_sdk_api:context(),
    Response :: map()
) -> temporal_sdk_client:cast_result().
respond_query_task_completed(ApiContext, Response) ->
    #{worker_opts := #{namespace := Namespace}} = ApiContext,
    CompletedType =
        case Response of
            #{answer := _} -> 'QUERY_RESULT_TYPE_ANSWERED';
            #{} -> 'QUERY_RESULT_TYPE_FAILED'
        end,
    Msg1 =
        case Response of
            #{answer := A} ->
                M = maps:without([answer], Response),
                M#{query_result => A};
            #{} ->
                Response
        end,
    Msg = Msg1#{namespace => Namespace, completed_type => CompletedType},
    temporal_sdk_api:request('RespondQueryTaskCompleted', ApiContext, Msg, cast).

reset_workflow_execution(ApiContext, Reason, WorkflowTaskFinishEventId) ->
    MsgName = 'temporal.api.workflowservice.v1.ResetWorkflowExecutionRequest',
    #{
        worker_opts := #{namespace := Namespace},
        task_opts := #{workflow_id := WorkflowId, run_id := RunId}
    } = ApiContext,
    Msg = temporal_sdk_api:put_id(
        ApiContext,
        MsgName,
        request_id,
        #{
            namespace => Namespace,
            workflow_execution => #{workflow_id => WorkflowId, run_id => RunId},
            reason => Reason,
            workflow_task_finish_event_id => WorkflowTaskFinishEventId
        }
    ),
    temporal_sdk_api:request('ResetWorkflowExecution', ApiContext, Msg, cast).
