-module(temporal_sdk_api_context).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    build/1,
    activity_from_workflow/1,
    update/2,
    take_next_page_token/1,
    add_activity_opts/3,
    add_activity_opts/4,
    add_nexus_task_opts/2,
    add_workflow_opts/3,
    restart_workflow_task_opts/2,
    add_limiter_counters/3
]).

-spec build(Cluster :: temporal_sdk_cluster:cluster_name()) ->
    {ok, temporal_sdk_api:context()} | {error, invalid_cluster}.
build(Cluster) ->
    case temporal_sdk_cluster_sup:get_context(Cluster) of
        {ok, ApiContext} -> {ok, ApiContext#{worker_identity => self()}};
        Err -> Err
    end.

-spec activity_from_workflow(WFApiContext :: temporal_sdk_api:context()) ->
    ActivityApiContext :: temporal_sdk_api:context().
activity_from_workflow(WFApiContext) ->
    #{worker_opts := WFWorkerOpts} = WFApiContext,
    #{task_settings := #{eager_execution_settings := EagerExecutionSettings}} = WFWorkerOpts,
    WO = maps:with([task_queue, failure_info, worker_version], WFWorkerOpts),
    WorkerOpts = WO#{
        worker_id => eager_execution_worker,
        namespace => <<>>,
        task_settings => EagerExecutionSettings,
        allowed_temporal_names => all,
        allowed_erlang_modules => all,
        temporal_name_to_erlang => fun temporal_sdk_api:temporal_name_to_erlang/2
    },
    C = maps:with([cluster, client_opts, worker_identity], WFApiContext),
    C#{worker_opts => WorkerOpts}.

-spec update(
    ApiContext :: temporal_sdk_api:context(),
    Task ::
        temporal_sdk_workflow:task()
        | temporal_sdk_activity:task()
        | #{task_token := undefined | unicode:chardata()}
) -> UpdatedApiContext :: temporal_sdk_api:context().
update(#{task_opts := TaskOpts} = ApiContext, #{task_token := TaskToken}) ->
    ApiContext#{task_opts := TaskOpts#{token := TaskToken}};
update(#{task_opts := _} = ApiContext, #{}) ->
    ApiContext.

-spec take_next_page_token(ApiContext :: temporal_sdk_api:context()) ->
    {NextPageToken :: unicode:chardata(), temporal_sdk_api:context()}.
take_next_page_token(#{task_opts := #{next_page_token := NextPageToken} = TaskOpts} = ApiContext) ->
    {NextPageToken, ApiContext#{task_opts := maps:without([next_page_token], TaskOpts)}}.

-spec add_activity_opts(
    ApiContext :: temporal_sdk_api:context(),
    Task :: temporal_sdk_activity:task() | #{task_token := undefined},
    ExecutionModule :: module()
) ->
    ApiContextWithOpts :: temporal_sdk_api:context().
add_activity_opts(ApiContext, #{task_token := TaskToken}, ExecutionModule) ->
    ApiContext#{task_opts => #{token => TaskToken}, execution_module => ExecutionModule}.

-spec add_activity_opts(
    ApiContext :: temporal_sdk_api:context(),
    Task :: temporal_sdk_activity:task() | #{task_token := undefined},
    IndexKey :: temporal_sdk_workflow:activity(),
    ExecutionModule :: module()
) ->
    ApiContextWithOpts :: temporal_sdk_api:context().
add_activity_opts(ApiContext, #{task_token := TaskToken}, IndexKey, ExecutionModule) ->
    ApiContext#{
        task_opts => #{token => TaskToken, index_key => IndexKey},
        execution_module => ExecutionModule
    }.

-spec add_nexus_task_opts(
    ApiContext :: temporal_sdk_api:context(),
    Task :: temporal_sdk_nexus:task()
) ->
    ApiContextWithTaskOpts :: temporal_sdk_api:context().
add_nexus_task_opts(ApiContext, #{task_token := TaskToken}) ->
    ApiContext#{task_opts => #{token => TaskToken}}.

-spec add_workflow_opts(
    ApiContext :: temporal_sdk_api:context(),
    Task :: temporal_sdk_workflow:task(),
    ExecutionModule :: module()
) ->
    ApiContextWithTaskOpts :: temporal_sdk_api:context().
add_workflow_opts(
    #{worker_opts := #{task_queue := TaskQueue}} = ApiContext,
    #{
        task_token := TaskToken,
        next_page_token := NextPageToken,
        workflow_type := #{name := WorkflowTypeName},
        workflow_execution := #{workflow_id := WorkflowId, run_id := RunId}
    } =
        Task,
    ExecutionModule
) when not is_function(TaskQueue) ->
    StickyName = temporal_sdk_utils_path:string_path([
        node(), pid_to_list(self()), temporal_sdk_utils:uuid4()
    ]),
    ApiContext#{
        execution_module => ExecutionModule,
        task_opts => #{
            token => TaskToken,
            next_page_token => NextPageToken,
            workflow_type => WorkflowTypeName,
            workflow_id => WorkflowId,
            run_id => RunId,
            sticky_attributes => #{
                worker_task_queue => #{
                    name => StickyName,
                    kind => 'TASK_QUEUE_KIND_STICKY',
                    normal_name => TaskQueue
                },
                schedule_to_start_timeout => fetch_sticky_execution_schedule_to_start_timeout(
                    ApiContext, Task
                )
            }
        }
    }.

fetch_sticky_execution_schedule_to_start_timeout(
    #{worker_opts := #{task_settings := #{sticky_execution_schedule_to_start_ratio := Ratio}}}, Task
) ->
    case temporal_sdk_api_workflow_task:workflow_task_timeout_msec(Task) of
        T when is_integer(T) -> temporal_sdk_utils_time:msec_to_protobuf(round(T * Ratio));
        _ -> temporal_sdk_utils_time:msec_to_protobuf(5_000)
    end.

-spec restart_workflow_task_opts(
    ApiContext :: temporal_sdk_api:context(),
    Task :: temporal_sdk_workflow:task()
) ->
    ApiContextWithTaskOpts :: temporal_sdk_api:context().
restart_workflow_task_opts(
    #{task_opts := TaskOpts} = ApiContext,
    #{
        task_token := TaskToken,
        next_page_token := NextPageToken,
        workflow_execution := #{run_id := RunId}
    }
) ->
    % eqwalizer:ignore
    ApiContext#{
        task_opts := TaskOpts#{
            token := TaskToken, next_page_token => NextPageToken, run_id := RunId
        }
    }.

-spec add_limiter_counters(
    ApiContext :: temporal_sdk_api:context(),
    WorkerType :: temporal_sdk_worker:worker_type(),
    LimiterCounters :: temporal_sdk_limiter:counters()
) ->
    ApiContextWithLimiters ::
        temporal_sdk_api:context()
        | {invalid_opts, Reason :: map()}.
add_limiter_counters(ApiContext, activity, LimiterCounters) ->
    do_add_limiter_counters(ApiContext, [activity_regular], LimiterCounters, []);
add_limiter_counters(ApiContext, session, LimiterCounters) ->
    do_add_limiter_counters(ApiContext, [activity_session], LimiterCounters, []);
add_limiter_counters(ApiContext, nexus, LimiterCounters) ->
    do_add_limiter_counters(ApiContext, [nexus], LimiterCounters, []);
add_limiter_counters(ApiContext, workflow, LimiterCounters) ->
    do_add_limiter_counters(
        ApiContext, [workflow, activity_eager, activity_direct], LimiterCounters, []
    ).

do_add_limiter_counters(ApiContext, [L | TLimitables], LimiterCounters, Acc) ->
    case temporal_sdk_limiter:build_counters(L, LimiterCounters) of
        {ok, C} -> do_add_limiter_counters(ApiContext, TLimitables, LimiterCounters, [C | Acc]);
        Err -> Err
    end;
do_add_limiter_counters(ApiContext, [], _LimiterCounters, Acc) ->
    ApiContext#{limiter_counters => lists:reverse(Acc)}.
