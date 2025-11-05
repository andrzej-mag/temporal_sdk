-module(temporal_sdk_api_workflow_task).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    input/2,
    task_from_history/1,
    is_history_closed/1,
    build_context_workflow_info/2,
    task_token/1,
    workflow_execution/1,
    workflow_execution_workflow_id/1,
    workflow_execution_run_id/1,
    workflow_type/1,
    previous_started_event_id/1,
    started_event_id/1,
    attempt/1,
    backlog_count_hint/1,
    history_events/1,
    next_page_token/1,
    workflow_execution_task_queue/1,
    scheduled_time_nanos/1,
    started_time_nanos/1,
    %% fetched from history event WorkflowExecutionStartedEventAttributes:
    workflow_execution_started_event_attributes/1,
    workflow_execution_timeout_msec/1,
    workflow_run_timeout_msec/1,
    workflow_task_timeout_msec/1,
    has_started_event/1
]).

-include("proto.hrl").

-spec input(ApiCtx :: temporal_sdk_api:context(), Task :: temporal_sdk_workflow:task()) ->
    temporal_sdk:term_from_payloads().
input(ApiCtx, Task) ->
    temporal_sdk_api:map_from_payloads(
        ApiCtx,
        'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes',
        input,
        maps:get(input, workflow_execution_started_event_attributes(Task), #{payloads => []})
    ).

-spec task_from_history(History :: ?TEMPORAL_SPEC:'temporal.api.history.v1.History'()) ->
    {ok, temporal_sdk_workflow:task()}
    | {error, malformed_history}.
task_from_history(
    #{events := [#{attributes := {workflow_execution_started_event_attributes, Attr}} | _] = Events} =
        History
) ->
    #{attempt := At, task_queue := TQ, workflow_id := WId, workflow_type := WTy} = Attr,
    T = #{
        history => History,
        task_token => <<>>,
        next_page_token => <<>>,
        attempt => At,
        backlog_count_hint => 0,
        messages => [],
        previous_started_event_id => length(Events),
        started_event_id => 0,
        queries => #{},
        scheduled_time => #{nanos => 0, seconds => 0},
        started_time => #{nanos => 0, seconds => 0},
        workflow_execution => #{run_id => temporal_sdk_utils:uuid4(), workflow_id => WId},
        workflow_execution_task_queue => TQ,
        workflow_type => WTy
    },
    {ok, T};
task_from_history(_InvalidHistory) ->
    {error, malformed_history}.

-spec is_history_closed(
    History ::
        ?TEMPORAL_SPEC:'temporal.api.history.v1.History'()
        | HistoryEvents :: [?TEMPORAL_SPEC:'temporal.api.history.v1.HistoryEvent'()]
) ->
    true
    | {error, unclosed_history}.
is_history_closed(#{events := []}) ->
    {error, unclosed_history};
is_history_closed(#{events := [_ | _] = Events}) ->
    do_is_history_closed(lists:last(Events));
is_history_closed([]) ->
    {error, unclosed_history};
is_history_closed([_ | _] = Events) ->
    do_is_history_closed(lists:last(Events)).

do_is_history_closed(#{event_type := E}) when
    E =:= 'EVENT_TYPE_WORKFLOW_EXECUTION_COMPLETED';
    E =:= 'EVENT_TYPE_WORKFLOW_EXECUTION_CANCELED';
    E =:= 'EVENT_TYPE_WORKFLOW_EXECUTION_FAILED';
    E =:= 'EVENT_TYPE_WORKFLOW_EXECUTION_CONTINUED_AS_NEW'
->
    true;
do_is_history_closed(#{}) ->
    {error, unclosed_history}.

-doc false.
-spec build_context_workflow_info(temporal_sdk_api:context(), temporal_sdk_workflow:task()) ->
    temporal_sdk_workflow:context_workflow_info().
build_context_workflow_info(ApiContext, Task) ->
    #{
        workflow_execution := WorkflowExecution,
        workflow_execution_task_queue := #{name := WorkflowExecutionTaskQueue}
    } = Task,
    #{
        workflow_type := #{name := WorkflowType},
        task_queue := #{name := TaskQueue},
        attempt := Attempt
    } = TaskAttributes = workflow_execution_started_event_attributes(Task),
    WorkflowExecutionTimeoutMsec = task_timeout(TaskAttributes, workflow_execution_timeout),
    WorkflowRunTimeoutMsec = task_timeout(TaskAttributes, workflow_run_timeout),
    WorkflowTaskTimeoutMsec = task_timeout(TaskAttributes, workflow_task_timeout),

    MsgName = 'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes',
    R1 =
        case TaskAttributes of
            #{last_completion_result := LastCompletionResult} ->
                #{
                    last_completion_result => temporal_sdk_api:map_from_payloads(
                        ApiContext, MsgName, last_completion_result, LastCompletionResult
                    )
                };
            #{} ->
                #{}
        end,
    R2 =
        case TaskAttributes of
            #{memo := #{fields := MemoFields}} ->
                R1#{
                    memo => temporal_sdk_api:map_from_mapstring_payload(
                        ApiContext, MsgName, [memo, fields], MemoFields
                    )
                };
            #{} ->
                R1
        end,
    R3 =
        case TaskAttributes of
            #{search_attributes := #{indexed_fields := SearchAttrIF}} ->
                R2#{
                    search_attributes => temporal_sdk_api:map_from_mapstring_payload(
                        ApiContext, MsgName, [search_attributes, indexed_fields], SearchAttrIF
                    )
                };
            #{} ->
                R2
        end,

    R3#{
        workflow_execution => WorkflowExecution,
        workflow_execution_task_queue => WorkflowExecutionTaskQueue,
        workflow_type => WorkflowType,
        task_queue => TaskQueue,
        workflow_execution_timeout_msec => WorkflowExecutionTimeoutMsec,
        workflow_run_timeout_msec => WorkflowRunTimeoutMsec,
        workflow_task_timeout_msec => WorkflowTaskTimeoutMsec,
        attempt => Attempt
    }.

-doc false.
-spec task_token(temporal_sdk_workflow:task()) -> iodata().
task_token(#{task_token := V}) -> V.

-spec workflow_execution(temporal_sdk_workflow:task()) ->
    ?TEMPORAL_SPEC:'temporal.api.common.v1.WorkflowExecution'().
workflow_execution(#{workflow_execution := V}) -> V.

-spec workflow_execution_workflow_id(temporal_sdk_workflow:task()) -> unicode:chardata().
workflow_execution_workflow_id(#{workflow_execution := #{workflow_id := V}}) -> V.

-spec workflow_execution_run_id(temporal_sdk_workflow:task()) -> unicode:chardata().
workflow_execution_run_id(#{workflow_execution := #{run_id := V}}) -> V.

-spec workflow_type(temporal_sdk_workflow:task()) -> unicode:chardata().
workflow_type(#{workflow_type := #{name := V}}) -> V.

-spec previous_started_event_id(temporal_sdk_workflow:task()) -> non_neg_integer().
previous_started_event_id(#{previous_started_event_id := V}) -> V.

-spec started_event_id(temporal_sdk_workflow:task()) -> non_neg_integer().
started_event_id(#{previous_started_event_id := V}) -> V.

-spec attempt(temporal_sdk_workflow:task()) -> pos_integer().
attempt(#{attempt := V}) -> V.

-spec backlog_count_hint(temporal_sdk_workflow:task()) -> non_neg_integer().
backlog_count_hint(#{backlog_count_hint := V}) -> V.

-spec history_events(temporal_sdk_workflow:task()) ->
    [?TEMPORAL_SPEC:'temporal.api.history.v1.HistoryEvent'()].
history_events(#{history := #{events := V}}) -> V.

-doc false.
-spec next_page_token(temporal_sdk_workflow:task()) -> iodata().
next_page_token(#{next_page_token := V}) -> V.

-spec workflow_execution_task_queue(temporal_sdk_workflow:task()) -> unicode:chardata().
workflow_execution_task_queue(#{workflow_execution_task_queue := #{name := V}}) -> V.

-spec scheduled_time_nanos(temporal_sdk_workflow:task()) -> integer().
scheduled_time_nanos(#{scheduled_time := V}) -> temporal_sdk_utils_time:protobuf_to_nanos(V).

-spec started_time_nanos(temporal_sdk_workflow:task()) -> integer().
started_time_nanos(#{started_time := V}) -> temporal_sdk_utils_time:protobuf_to_nanos(V).

-spec workflow_execution_started_event_attributes(temporal_sdk_workflow:task()) ->
    ?TEMPORAL_SPEC:'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'().
workflow_execution_started_event_attributes(
    %% From Temporal docs:
    %% WorkflowExecutionStartedEventAttributes is always the first event in workflow history.
    #{
        history := #{
            events := [#{attributes := {workflow_execution_started_event_attributes, Attr}} | _]
        }
    }
) ->
    Attr.

-spec workflow_execution_timeout_msec(temporal_sdk_workflow:task()) -> erlang:timeout().
workflow_execution_timeout_msec(Task) ->
    task_timeout(workflow_execution_started_event_attributes(Task), workflow_execution_timeout).

-spec workflow_run_timeout_msec(temporal_sdk_workflow:task()) -> erlang:timeout().
workflow_run_timeout_msec(Task) ->
    task_timeout(workflow_execution_started_event_attributes(Task), workflow_run_timeout).

-spec workflow_task_timeout_msec(temporal_sdk_workflow:task()) -> erlang:timeout().
workflow_task_timeout_msec(Task) ->
    task_timeout(workflow_execution_started_event_attributes(Task), workflow_task_timeout).

task_timeout(TaskAttributes, TimeoutKey) ->
    case TaskAttributes of
        #{TimeoutKey := T} when is_map(T) -> temporal_sdk_utils_time:protobuf_to_msec(T);
        _ -> infinity
    end.

has_started_event(
    #{
        history := #{
            events := [#{attributes := {workflow_execution_started_event_attributes, _}} | _]
        }
    }
) ->
    true;
has_started_event(_Task) ->
    false.
