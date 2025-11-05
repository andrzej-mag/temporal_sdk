-module(temporal_sdk_api_awaitable_index).

% elp:ignore W0012 W0040
-moduledoc false.

-include("proto.hrl").

-export([
    cast/2,
    cast_key/2,
    cast_value/3,
    cast_list/2,
    is_valid/1,
    set_event/2,
    to_event/2,
    to_key/1,
    transit/3,
    is_closed/2,
    is_ready/2,
    merge_data/3,
    from_event/5,
    from_poll/2
]).

-define(DEFAULT_PAYLOADS, #{payloads => []}).

cast(Pattern, #{client_opts := #{grpc_opts := #{codec := {Codec, _, _}}}}) ->
    IndexKey = to_key(Pattern),
    case is_valid(IndexKey) of
        true -> do_cast(Pattern, Codec);
        false -> erlang:error(invalid_pattern, [Pattern])
    end.

cast_key(Pattern, #{client_opts := #{grpc_opts := #{codec := {Codec, _, _}}}}) ->
    IndexKey = to_key(Pattern),
    case is_valid(IndexKey) of
        true -> {do_cast(Pattern, Codec), do_cast(IndexKey, Codec)};
        false -> erlang:error(invalid_pattern, [Pattern])
    end.

do_cast({I, Pattern}, _CastMod) when I =:= info; I =:= event; I =:= execution -> {I, Pattern};
do_cast(Pattern, CastMod) ->
    [I | Names] = tuple_to_list(Pattern),
    CastFn = fun
        ('_') -> '_';
        (N) -> CastMod:cast(N)
    end,
    CastedNames = lists:map(CastFn, Names),
    list_to_tuple([I | CastedNames]).

cast_value(A, Value, _ApiCtx) when A =:= execution; A =:= info ->
    Value;
cast_value(_Awaitable, Value, #{client_opts := #{grpc_opts := #{codec := {Codec, _, _}}}}) ->
    Codec:cast(Value).

cast_list(Pattern, #{client_opts := #{grpc_opts := #{codec := {Codec, _, _}}}}) when
    is_list(Pattern)
->
    [I | Names] = Pattern,
    CastFn = fun
        ('_') -> '_';
        (N) -> Codec:cast(N)
    end,
    CastedNames = lists:map(CastFn, Names),
    [I | CastedNames].

%% Temporal events
%% SDK
is_valid({info, _Id}) -> true;
is_valid({execution, _Id}) -> true;
%% Temporal
is_valid({activity, _Id}) -> true;
is_valid({marker, _Type, _Name}) -> true;
is_valid({timer, _Id}) -> true;
is_valid({child_workflow, _Id}) -> true;
is_valid({nexus, _Endpoint, _Service, _Operation}) -> true;
is_valid({signal_external_workflow, _NS, _WId, _RId, _Name}) -> true;
is_valid({search_attributes}) -> true;
is_valid({workflow_properties}) -> true;
is_valid({complete_workflow_execution}) -> true;
is_valid({cancel_workflow_execution}) -> true;
is_valid({fail_workflow_execution}) -> true;
is_valid({continue_as_new_workflow}) -> true;
%% External
is_valid({cancel_request}) -> true;
is_valid({signal, _Name}) -> true;
is_valid({query, _Type}) -> true;
is_valid({update, _Id}) -> true;
%% Event
is_valid({event, Event}) -> is_valid_event(Event);
%% SDK
is_valid({suggest_continue_as_new}) -> true;
%% Invalid
is_valid(_Invalid) -> false.

is_valid_event({Id, Type, Attr, Data}) when
    (is_integer(Id) orelse Id =:= '_') andalso is_atom(Type) andalso
        (is_map(Attr) orelse Attr =:= '_') andalso
        (is_map(Data) orelse Data =:= '_')
->
    true;
is_valid_event(_) ->
    false.

set_event(Awaitable, #{awaitable_event := Event}) ->
    [A | TA] = tuple_to_list(to_key(Awaitable)),
    AEvent = to_event(A, Event),
    list_to_tuple([AEvent | TA]);
set_event(Awaitable, #{}) ->
    Awaitable.

%% SDK
to_event(info, _) -> info;
to_event(execution, cmd) -> execution_cmd;
to_event(execution, start) -> execution_start;
to_event(execution, close) -> execution;
%% activity
to_event(activity, cmd) -> activity_cmd;
to_event(activity, cancel_request) -> activity_cancel_request;
to_event(activity, result) -> activity_result;
to_event(activity, schedule) -> activity_schedule;
to_event(activity, start) -> activity_start;
to_event(activity, close) -> activity;
%% marker
to_event(marker, cmd) -> marker_cmd;
to_event(marker, value) -> marker_value;
to_event(marker, close) -> marker;
%% timer
to_event(timer, cmd) -> timer_cmd;
to_event(timer, cancel_request) -> timer_cancel_request;
to_event(timer, start) -> timer_start;
to_event(timer, close) -> timer;
%% child_workflow
to_event(child_workflow, cmd) -> child_workflow_cmd;
to_event(child_workflow, initiate) -> child_workflow_initiate;
to_event(child_workflow, start) -> child_workflow_start;
to_event(child_workflow, close) -> child_workflow;
%% nexus
to_event(nexus, cmd) -> nexus_cmd;
to_event(nexus, cancel_request) -> nexus_cancel_request;
to_event(nexus, schedule) -> nexus_schedule;
to_event(nexus, start) -> nexus_start;
to_event(nexus, close) -> nexus;
%% workflow_properties
to_event(workflow_properties, cmd) -> workflow_properties_cmd;
to_event(workflow_properties, close) -> workflow_properties;
%% workflow_execution
to_event(complete_workflow_execution, cmd) -> complete_workflow_execution_cmd;
to_event(complete_workflow_execution, close) -> complete_workflow_execution;
to_event(cancel_workflow_execution, cmd) -> cancel_workflow_execution_cmd;
to_event(cancel_workflow_execution, close) -> cancel_workflow_execution;
to_event(fail_workflow_execution, cmd) -> fail_workflow_execution_cmd;
to_event(fail_workflow_execution, close) -> fail_workflow_execution;
to_event(continue_as_new_workflow, cmd) -> continue_as_new_workflow_cmd;
to_event(continue_as_new_workflow, close) -> continue_as_new_workflow;
%% query
to_event(query, request) -> query_request;
to_event(query, response) -> query_response;
to_event(query, close) -> query;
%% signal
to_event(signal, request) -> signal_request;
to_event(signal, admit) -> signal_admit;
to_event(signal, close) -> signal.

%% SDK
to_key({info, InfoId}) -> {info, InfoId};
to_key({execution_cmd, ExecutionId}) -> {execution, ExecutionId};
to_key({execution_start, ExecutionId}) -> {execution, ExecutionId};
to_key({execution, ExecutionId}) -> {execution, ExecutionId};
to_key({event, Event}) -> {event, Event};
to_key({suggest_continue_as_new}) -> {suggest_continue_as_new};
%% activity
to_key({activity_cmd, Id}) -> {activity, Id};
to_key({activity_cancel_request, Id}) -> {activity, Id};
to_key({activity_result, Id}) -> {activity, Id};
to_key({activity_schedule, Id}) -> {activity, Id};
to_key({activity_start, Id}) -> {activity, Id};
to_key({activity, Id}) -> {activity, Id};
%% marker
to_key({marker_cmd, Type, Name}) -> {marker, Type, Name};
to_key({marker_value, Type, Name}) -> {marker, Type, Name};
to_key({marker, Type, Name}) -> {marker, Type, Name};
%% timer
to_key({timer_cmd, Name}) -> {timer, Name};
to_key({timer_cancel_request, Name}) -> {timer, Name};
to_key({timer_start, Name}) -> {timer, Name};
to_key({timer, Name}) -> {timer, Name};
%% child_workflow
to_key({child_workflow_cmd, Id}) -> {child_workflow, Id};
to_key({child_workflow_initiate, Id}) -> {child_workflow, Id};
to_key({child_workflow_start, Id}) -> {child_workflow, Id};
to_key({child_workflow, Id}) -> {child_workflow, Id};
%% nexus
to_key({nexus_cmd, E, S, O}) -> {nexus, E, S, O};
to_key({nexus_cancel_request, E, S, O}) -> {nexus, E, S, O};
to_key({nexus_schedule, E, S, O}) -> {nexus, E, S, O};
to_key({nexus_start, E, S, O}) -> {nexus, E, S, O};
to_key({nexus, E, S, O}) -> {nexus, E, S, O};
%% workflow_properties
to_key({workflow_properties_cmd}) -> {workflow_properties};
to_key({workflow_properties}) -> {workflow_properties};
%% workflow_execution
to_key({complete_workflow_execution_cmd}) -> {complete_workflow_execution};
to_key({complete_workflow_execution}) -> {complete_workflow_execution};
to_key({cancel_workflow_execution_cmd}) -> {cancel_workflow_execution};
to_key({cancel_workflow_execution}) -> {cancel_workflow_execution};
to_key({fail_workflow_execution_cmd}) -> {fail_workflow_execution};
to_key({fail_workflow_execution}) -> {fail_workflow_execution};
to_key({continue_as_new_workflow_cmd}) -> {continue_as_new_workflow};
to_key({continue_as_new_workflow}) -> {continue_as_new_workflow};
%% external
to_key({cancel_request}) -> {cancel_request};
to_key({signal_request, N}) -> {signal, N};
to_key({signal_admit, N}) -> {signal, N};
to_key({signal, N}) -> {signal, N};
to_key({query_request, N}) -> {query, N};
to_key({query_response, N}) -> {query, N};
to_key({query, N}) -> {query, N};
%% invalid
to_key(_Invalid) -> invalid_pattern.

%% Function counts only commands closings and non-deadlocking cancelations.
%% Commands openings are counted with temporal_sdk_api_command:awaitable_command_count/1.
%% Deadlocking cancelation commands are counted with temporal_sdk_executor_workflow:do_cmds/5.
%% Additionally there are exceptions in temporal_sdk_api_awaitable_index_table:upsert_and_count/2.
-spec transit(
    AwaitableType :: atom(),
    OldData :: temporal_sdk_workflow:awaitable_index_data() | noevent,
    NewData :: temporal_sdk_workflow:awaitable_data()
) -> 1 | 0 | invalid.
%
transit(execution, noevent, #{state := cmd}) -> 0;
transit(execution, #{state := cmd}, #{state := started}) -> 0;
transit(execution, #{state := started}, #{state := started}) -> 0;
transit(execution, #{state := started}, #{state := completed}) -> 0;
transit(execution, #{state := completed}, #{state := completed}) -> 0;
%
transit(activity, noevent, #{state := cmd}) -> 0;
transit(activity, #{state := cmd}, #{state := cmd, cancel_requested := true}) -> 0;
transit(activity, #{state := cmd, event_id := A}, #{state := cmd, event_id := B}) when B > A -> 0;
transit(activity, #{state := cmd}, #{state := scheduled}) -> 0;
transit(activity, #{state := cmd, direct_execution := true}, #{result := _}) -> 0;
transit(activity, #{state := cmd, direct_execution := true}, #{last_failure := _}) -> 0;
transit(activity, #{state := scheduled}, #{state := scheduled, cancel_requested := true}) -> 0;
transit(activity, #{state := scheduled}, #{state := started}) -> 0;
transit(activity, #{state := scheduled}, #{state := canceled}) -> 1;
transit(activity, #{state := scheduled, direct_execution := true}, #{result := _}) -> 0;
transit(activity, #{state := scheduled, direct_execution := true}, #{last_failure := _}) -> 0;
transit(activity, #{state := started}, #{state := started, cancel_requested := true}) -> 0;
transit(activity, #{state := started}, #{state := completed}) -> 1;
transit(activity, #{state := started}, #{state := canceled}) -> 1;
transit(activity, #{state := started}, #{state := failed}) -> 1;
transit(activity, #{state := started}, #{state := timedout}) -> 1;
transit(activity, #{state := started, direct_execution := true}, #{result := _}) -> 0;
transit(activity, #{state := started, direct_execution := true}, #{last_failure := _}) -> 0;
transit(activity, #{state := completed}, #{state := cmd}) -> 0;
transit(activity, #{state := canceled}, #{state := cmd}) -> 0;
transit(activity, #{state := failed}, #{state := cmd}) -> 0;
transit(activity, #{state := timedout}, #{state := cmd}) -> 0;
%
%% Message markers are excepted in temporal_sdk_api_awaitable_index_table:upsert_and_count/2.
transit(marker, #{state := cmd}, #{state := cmd, mutable := true, value := _}) -> 0;
transit(marker, #{state := cmd}, #{state := cmd, mutable := true}) -> invalid;
transit(marker, noevent, #{state := cmd}) -> 0;
transit(marker, #{state := cmd}, #{state := cmd}) -> 0;
transit(marker, #{state := cmd}, #{state := recorded}) -> 0;
transit(marker, #{state := recorded}, #{state := cmd}) -> 0;
transit(marker, #{state := recorded, event_id := _}, #{state := recorded, event_id := _}) -> 0;
%
transit(timer, noevent, #{state := cmd}) -> 0;
transit(timer, #{state := cmd}, #{state := cmd}) -> 0;
transit(timer, #{state := cmd}, #{state := started}) -> 0;
transit(timer, #{state := started}, #{state := started, cancel_requested := true}) -> 0;
transit(timer, #{state := started}, #{state := fired}) -> 1;
%% 'COMMAND_TYPE_CANCEL_TIMER' is deadlocking
transit(timer, #{state := started}, #{state := canceled}) -> 0;
transit(timer, #{state := fired}, #{state := cmd}) -> 0;
transit(timer, #{state := canceled}, #{state := cmd}) -> 0;
%
%% Temporal server allows multiple open child workflow executions with the same child workflow id.
%% Erlang SDK doesn't allow duplicate open child workflow executions with the same workflow id.
%% Starting a child workflow with the same workflow id (and the same type) as already opened child
%% workflow will cause parent workflow execution failure. Such behavior corresponds to the
%% StartWorkflowExecutionRequest behavior set with <workflow_id_conflict_policy> to
%% WORKFLOW_ID_CONFLICT_POLICY_FAIL. This is default behavior of regular workflows.
%% Using temporal.api.enums.v1.WorkflowIdConflictPolicy is not supported by Temporal server for
%% child workflows.
%% Additionally above behavior is consistent with activities behavior: workflow execution fails on
%% duplicate activity id for open activities.
transit(child_workflow, noevent, #{state := cmd}) -> 0;
transit(child_workflow, #{state := cmd}, #{state := initiated}) -> 0;
transit(child_workflow, #{state := initiated}, #{state := initiate_failed}) -> 1;
transit(child_workflow, #{state := initiated}, #{state := started}) -> 0;
transit(child_workflow, #{state := started}, #{state := completed}) -> 1;
transit(child_workflow, #{state := started}, #{state := failed}) -> 1;
transit(child_workflow, #{state := started}, #{state := canceled}) -> 1;
transit(child_workflow, #{state := started}, #{state := timedout}) -> 1;
transit(child_workflow, #{state := started}, #{state := terminated}) -> 1;
transit(child_workflow, #{state := initiate_failed}, #{state := cmd}) -> 0;
transit(child_workflow, #{state := completed}, #{state := cmd}) -> 0;
transit(child_workflow, #{state := failed}, #{state := cmd}) -> 0;
transit(child_workflow, #{state := canceled}, #{state := cmd}) -> 0;
transit(child_workflow, #{state := timedout}, #{state := cmd}) -> 0;
transit(child_workflow, #{state := terminated}, #{state := cmd}) -> 0;
%
transit(nexus, noevent, #{state := cmd}) -> 0;
transit(nexus, #{state := cmd}, #{state := cmd}) -> 0;
transit(nexus, #{state := cmd}, #{state := scheduled}) -> 0;
transit(nexus, #{state := scheduled}, #{state := scheduled, cancel_requested := true}) -> 0;
transit(nexus, #{state := scheduled}, #{state := started}) -> 0;
transit(nexus, #{state := started}, #{state := started, cancel_requested := true}) -> 0;
transit(nexus, #{state := started}, #{state := completed}) -> 1;
transit(nexus, #{state := started}, #{state := canceled}) -> 1;
transit(nexus, #{state := completed}, #{state := cmd}) -> 0;
transit(nexus, #{state := canceled}, #{state := cmd}) -> 0;
%
transit(workflow_properties, noevent, #{state := cmd}) -> 0;
transit(workflow_properties, #{state := cmd}, #{state := cmd}) -> 0;
transit(workflow_properties, #{state := cmd}, #{state := modified}) -> 0;
transit(workflow_properties, #{state := modified}, #{state := cmd}) -> 0;
transit(workflow_properties, #{state := modified}, #{state := modified}) -> 0;
%
transit(complete_workflow_execution, noevent, #{state := cmd}) -> 0;
transit(complete_workflow_execution, #{state := cmd}, #{state := cmd}) -> 0;
transit(complete_workflow_execution, #{state := cmd}, #{state := completed}) -> 0;
transit(cancel_workflow_execution, noevent, #{state := cmd}) -> 0;
transit(cancel_workflow_execution, #{state := cmd}, #{state := cmd}) -> 0;
transit(cancel_workflow_execution, #{state := cmd}, #{state := canceled}) -> 0;
transit(fail_workflow_execution, noevent, #{state := cmd}) -> 0;
transit(fail_workflow_execution, #{state := cmd}, #{state := cmd}) -> 0;
transit(fail_workflow_execution, #{state := cmd}, #{state := failed}) -> 0;
transit(continue_as_new_workflow, noevent, #{state := cmd}) -> 0;
transit(continue_as_new_workflow, #{state := cmd}, #{state := cmd}) -> 0;
transit(continue_as_new_workflow, #{state := cmd}, #{state := continued}) -> 0;
%
transit(signal, noevent, #{state := requested}) -> 0;
transit(signal, #{state := requested}, #{state := requested}) -> 0;
transit(signal, #{state := requested}, #{state := admitted}) -> 0;
transit(signal, #{state := admitted}, #{state := requested}) -> 0;
%
transit(query, noevent, #{state := requested}) -> 0;
transit(query, #{state := requested}, #{state := requested}) -> 0;
transit(query, #{state := requested}, #{state := responded}) -> 0;
transit(query, #{state := responded}, #{state := requested}) -> 0;
%
transit(cancel_request, noevent, #{state := requested}) -> 0;
%
transit(suggest_continue_as_new, noevent, #{state := suggested}) -> 0;
%
transit(_, _, _) -> invalid.

-spec is_closed(AwaitableType :: atom(), Match :: temporal_sdk_workflow:awaitable_match()) ->
    boolean().
is_closed(_AwaitableType, noevent) ->
    false;
is_closed(query, #{state := requested}) ->
    false;
is_closed(signal, #{state := admitted}) ->
    true;
is_closed(_AwaitableType, #{state := S}) when
    S =:= canceled;
    S =:= completed;
    S =:= failed;
    S =:= fired;
    S =:= modified;
    S =:= recorded;
    S =:= continued;
    S =:= initiate_failed;
    S =:= timedout;
    S =:= terminated;
    S =:= requested,
    S =:= responded,
    S =:= suggested
->
    true;
is_closed(_AwaitableType, _Match) ->
    false.

-spec is_ready(
    AwaitableType :: atom(),
    Match :: temporal_sdk_workflow:awaitable_match()
) -> boolean() | invalid_pattern.
is_ready(_AwaitableType, noevent) ->
    false;
%% info
is_ready(info, Match) when Match =/= noevent -> true;
%% execution
is_ready(execution_start, #{state := S}) when S == started; S == completed -> true;
is_ready(execution, #{state := S}) when S == completed -> true;
%% activity
is_ready(activity_cmd, #{state := S}) when
    S == cmd;
    S == scheduled;
    S == started;
    S == canceled;
    S == completed;
    S == failed;
    S == timedout
->
    true;
is_ready(activity_cancel_request, #{cancel_requested := true}) ->
    true;
is_ready(activity_result, #{result := _}) ->
    true;
is_ready(activity_schedule, #{state := S}) when
    S == scheduled; S == started; S == canceled; S == completed; S == failed; S == timedout
->
    true;
is_ready(activity_start, #{state := S}) when
    S == started; S == canceled; S == completed; S == failed; S == timedout
->
    true;
is_ready(activity_cancel_request, #{state := S}) when
    S == canceled; S == completed; S == failed; S == timedout
->
    true;
is_ready(activity, #{state := S}) when S == canceled; S == completed; S == failed; S == timedout ->
    true;
is_ready(activity_result, #{state := S}) when
    S == canceled; S == completed; S == failed; S == timedout
->
    true;
%% marker
is_ready(marker_cmd, #{state := S}) when S == cmd; S == recorded -> true;
is_ready(marker_value, #{value := _}) ->
    true;
is_ready(marker, #{state := S}) when S == recorded -> true;
%% timer
is_ready(timer_cmd, #{state := S}) when S == cmd; S == started; S == fired; S == canceled ->
    true;
is_ready(timer_cancel_request, #{cancel_requested := true}) ->
    true;
is_ready(timer_start, #{state := S}) when S == started; S == fired; S == canceled ->
    true;
is_ready(timer_cancel_request, #{state := S}) when S == fired; S == canceled -> true;
is_ready(timer, #{state := S}) when S == fired; S == canceled -> true;
%%
%% child_workflow
is_ready(child_workflow_cmd, #{state := S}) when
    S == cmd;
    S == initiated;
    S == initiate_failed;
    S == started;
    S == canceled;
    S == completed;
    S == failed;
    S == timedout;
    S == terminated
->
    true;
is_ready(child_workflow_initiate, #{state := S}) when
    S == initiated;
    S == initiate_failed;
    S == started;
    S == canceled;
    S == completed;
    S == failed;
    S == timedout;
    S == terminated
->
    true;
is_ready(child_workflow_start, #{state := S}) when
    S == initiate_failed;
    S == started;
    S == canceled;
    S == completed;
    S == failed;
    S == timedout;
    S == terminated
->
    true;
is_ready(child_workflow, #{state := S}) when
    S == initiate_failed;
    S == canceled;
    S == completed;
    S == failed;
    S == timedout;
    S == terminated
->
    true;
%% nexus
is_ready(nexus_cmd, #{state := S}) when
    S == cmd; S == scheduled; S == started; S == canceled; S == completed
->
    true;
is_ready(nexus_cancel_request, #{cancel_requested := true}) ->
    true;
is_ready(nexus_schedule, #{state := S}) when
    S == scheduled; S == started; S == canceled; S == completed
->
    true;
is_ready(nexus_start, #{state := S}) when S == started; S == canceled; S == completed ->
    true;
is_ready(nexus_cancel_request, #{state := S}) when S == canceled; S == completed ->
    true;
is_ready(nexus, #{state := S}) when S == canceled; S == completed -> true;
%% workflow_properties
is_ready(workflow_properties_cmd, #{state := S}) when S == cmd; S == modified -> true;
is_ready(workflow_properties, #{state := S}) when S == modified -> true;
%% signal
is_ready(signal_request, #{state := S}) when S == requested -> true;
is_ready(signal_admit, #{state := S}) when S == admitted -> true;
is_ready(signal, #{state := S}) when S == requested; S == admitted -> true;
%% query
is_ready(query_request, #{state := S}) when S == requested -> true;
is_ready(query_response, #{state := S}) when S == responded -> true;
is_ready(query, #{state := _S}) ->
    true;
%% workflow termination events cannot be awaited
%% is_ready(complete_workflow_execution_cmd, #{state := S}) when S == cmd; S == completed -> true;
%% is_ready(complete_workflow_execution, #{state := S}) when S == completed -> true;
%% is_ready(cancel_workflow_execution_cmd, #{state := S}) when S == cmd; S == canceled -> true;
%% is_ready(cancel_workflow_execution, #{state := S}) when S == canceled -> true;
%% is_ready(fail_workflow_execution_cmd, #{state := S}) when S == cmd; S == failed -> true;
%% is_ready(fail_workflow_execution, #{state := S}) when S == failed -> true;
%% is_ready(continue_as_new_workflow_cmd, #{state := S}) when S == cmd; S == continued -> true;
%% is_ready(continue_as_new_workflow, #{state := S}) when S == continued -> true;
is_ready(cancel_request, #{state := requested}) ->
    true;
%% event
is_ready(event, #{event_id := _}) ->
    true;
%% SDK
is_ready(suggest_continue_as_new, #{state := suggested}) ->
    true;
%% not awaited
is_ready(_AwaitableType, _Match) ->
    false.

-spec merge_data(
    AwaitableType :: atom(),
    OldData :: temporal_sdk_workflow:awaitable_index_data(),
    NewData :: temporal_sdk_workflow:awaitable_index_data()
) ->
    MergedData :: temporal_sdk_workflow:awaitable_index_data().
merge_data(_, noevent, NewData) ->
    NewData;
merge_data(_, #{state := S, history := H} = OD, #{state := S} = ND) when
    S =:= modified; S =:= recorded; S =:= requested
->
    % eqwalizer:ignore
    ND#{history => [maps:without([history], OD) | H]};
merge_data(_, #{state := S} = OD, #{state := S} = ND) when
    S =:= modified; S =:= recorded; S =:= requested
->
    ND#{history => [OD]};
merge_data(_, #{state := S, history := H} = OD, #{state := cmd} = ND) when
    S =:= completed;
    S =:= canceled;
    S =:= failed;
    S =:= fired;
    S =:= modified;
    S =:= recorded;
    S =:= requested;
    S =:= initiate_fail;
    S =:= timedout;
    S =:= terminated;
    S =:= upserted
->
    % eqwalizer:ignore
    ND#{history => [maps:without([history], OD) | H]};
merge_data(_, #{state := S} = OD, #{state := cmd} = ND) when
    S =:= completed;
    S =:= canceled;
    S =:= failed;
    S =:= fired;
    S =:= modified;
    S =:= recorded;
    S =:= requested;
    S =:= initiate_fail;
    S =:= timedout;
    S =:= terminated;
    S =:= upserted
->
    ND#{history => [OD]};
merge_data(_, #{state := responded, history := H} = OD, #{state := requested} = ND) ->
    % eqwalizer:ignore
    ND#{history => [maps:without([history], OD) | H]};
merge_data(_, #{state := responded} = OD, #{state := requested} = ND) ->
    ND#{history => [OD]};
merge_data(_, #{state := requested}, #{state := responded} = ND) ->
    ND;
%% signal
merge_data(signal, #{state := admitted, history := H} = OD, #{state := requested} = ND) ->
    % eqwalizer:ignore
    ND#{history => [maps:without([history], OD) | H]};
merge_data(signal, #{state := admitted} = OD, #{state := requested} = ND) ->
    ND#{history => [OD]};
merge_data(signal, #{state := requested, history := H} = OD, #{state := admitted} = ND) ->
    maps:merge(OD, ND#{history => admit_signal_history(H)});
%% remaining other
merge_data(_, OldData, NewData) ->
    % eqwalizer:ignore
    maps:merge(OldData, NewData).

admit_signal_history(History) ->
    Fn = fun
        (#{state := requested} = SignalData) -> SignalData#{state := admitted};
        (#{state := admitted} = SignalData) -> SignalData
    end,
    lists:map(Fn, History).

%% nexus
from_event(
    EventId,
    'EVENT_TYPE_NEXUS_OPERATION_SCHEDULED',
    #{endpoint := E, service := S, operation := O, input := I},
    _HistoryTable,
    ApiCtx
) ->
    MN = 'temporal.api.history.v1.NexusOperationScheduledEventAttributes',
    {
        {nexus, E, S, O},
        #{
            state => scheduled,
            event_id => EventId,
            input => temporal_sdk_api:map_from_payload(ApiCtx, MN, input, I)
        }
    };
%% activity
from_event(
    EventId,
    'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED',
    #{activity_id := Id},
    _HistoryTable,
    _ApiCtx
) ->
    {{activity, Id}, #{state => scheduled, event_id => EventId}};
from_event(
    EventId,
    'EVENT_TYPE_ACTIVITY_TASK_STARTED',
    #{scheduled_event_id := ScheduledEventId, attempt := Attempt} = Task,
    HistoryTable,
    ApiCtx
) ->
    case do_select_by_id(HistoryTable, ScheduledEventId) of
        {ScheduledEventId, 'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED', Attr} ->
            {IdxK, IdxV} = from_event(
                ScheduledEventId, 'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED', Attr, HistoryTable, ApiCtx
            ),
            Val = IdxV#{
                state := started,
                event_id := EventId,
                scheduled_event_id => ScheduledEventId,
                attempt => Attempt
            },
            case Task of
                #{last_failure := F} ->
                    {IdxK, Val#{last_failure => temporal_sdk_api_failure:from_temporal(ApiCtx, F)}};
                #{} ->
                    {IdxK, Val}
            end;
        InvalidEvent ->
            {error, #{
                reason => corrupted_event,
                expected_event => {ScheduledEventId, 'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED'},
                received_event => InvalidEvent
            }}
    end;
from_event(
    EventId,
    'EVENT_TYPE_ACTIVITY_TASK_COMPLETED',
    #{started_event_id := StartedEventId, result := Result},
    HistoryTable,
    ApiCtx
) ->
    case do_select_by_id(HistoryTable, StartedEventId) of
        {StartedEventId, 'EVENT_TYPE_ACTIVITY_TASK_STARTED', Attr} ->
            {IdxK, IdxV} = from_event(
                StartedEventId, 'EVENT_TYPE_ACTIVITY_TASK_STARTED', Attr, HistoryTable, ApiCtx
            ),
            MN = 'temporal.api.history.v1.ActivityTaskCompletedEventAttributes',
            {
                IdxK,
                IdxV#{
                    state := completed,
                    event_id := EventId,
                    started_event_id => StartedEventId,
                    result => temporal_sdk_api:map_from_payloads(ApiCtx, MN, result, Result)
                }
            };
        InvalidEvent ->
            {error, #{
                reason => corrupted_event,
                expected_event => {StartedEventId, 'EVENT_TYPE_ACTIVITY_TASK_STARTED'},
                received_event => InvalidEvent
            }}
    end;
from_event(
    EventId,
    'EVENT_TYPE_ACTIVITY_TASK_CANCEL_REQUESTED',
    #{scheduled_event_id := ScheduledEventId},
    HistoryTable,
    ApiCtx
) ->
    case do_select_by_id(HistoryTable, ScheduledEventId) of
        {ScheduledEventId, 'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED', Attr} ->
            {IdxK, IdxV} = from_event(
                ScheduledEventId, 'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED', Attr, HistoryTable, ApiCtx
            ),
            {IdxK, IdxV#{
                event_id := EventId,
                cancel_requested => true
            }};
        InvalidEvent ->
            {error, #{
                reason => corrupted_event,
                expected_event => {ScheduledEventId, 'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED'},
                received_event => InvalidEvent
            }}
    end;
from_event(
    EventId,
    'EVENT_TYPE_ACTIVITY_TASK_CANCELED',
    #{scheduled_event_id := SchEventId, started_event_id := StEventId, details := Details},
    HistoryTable,
    ApiCtx
) ->
    {IdxK, IdxV} =
        case do_select_by_id(HistoryTable, StEventId) of
            {EId, 'EVENT_TYPE_ACTIVITY_TASK_STARTED', Attr} ->
                from_event(EId, 'EVENT_TYPE_ACTIVITY_TASK_STARTED', Attr, HistoryTable, ApiCtx);
            _ ->
                {EId, 'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED', Attr} = do_select_by_id(
                    HistoryTable, SchEventId
                ),
                from_event(EId, 'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED', Attr, HistoryTable, ApiCtx)
        end,
    MN = 'temporal.api.history.v1.ActivityTaskCanceledEventAttributes',
    {
        IdxK,
        IdxV#{
            state := canceled,
            event_id := EventId,
            started_event_id => StEventId,
            details => temporal_sdk_api:map_from_payloads(ApiCtx, MN, details, Details)
        }
    };
from_event(
    EventId,
    'EVENT_TYPE_ACTIVITY_TASK_FAILED',
    #{
        scheduled_event_id := ScheduledEventId,
        started_event_id := StEventId,
        retry_state := RetryState
    } = Attr,
    HistoryTable,
    ApiCtx
) ->
    case do_select_by_id(HistoryTable, ScheduledEventId) of
        {ScheduledEventId, 'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED', SchAttr} ->
            {IdxK, IdxV} = from_event(
                ScheduledEventId,
                'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED',
                SchAttr,
                HistoryTable,
                ApiCtx
            ),
            Val = IdxV#{
                state := failed,
                event_id := EventId,
                started_event_id => StEventId,
                retry_state => RetryState
            },
            case Attr of
                #{failure := F} ->
                    {IdxK, Val#{failure => temporal_sdk_api_failure:from_temporal(ApiCtx, F)}};
                #{} ->
                    {IdxK, Val}
            end;
        InvalidEvent ->
            {error, #{
                reason => corrupted_event,
                expected_event => {ScheduledEventId, 'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED'},
                received_event => InvalidEvent
            }}
    end;
from_event(
    EventId,
    'EVENT_TYPE_ACTIVITY_TASK_TIMED_OUT',
    #{
        scheduled_event_id := ScheduledEventId,
        started_event_id := StEventId,
        retry_state := RetryState
    } = Attr,
    HistoryTable,
    ApiCtx
) ->
    case do_select_by_id(HistoryTable, ScheduledEventId) of
        {ScheduledEventId, 'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED', SchAttr} ->
            {IdxK, IdxV} = from_event(
                ScheduledEventId,
                'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED',
                SchAttr,
                HistoryTable,
                ApiCtx
            ),
            Val = IdxV#{
                state := timedout,
                event_id := EventId,
                started_event_id => StEventId,
                retry_state => RetryState
            },
            case Attr of
                #{failure := F} ->
                    {IdxK, Val#{failure => temporal_sdk_api_failure:from_temporal(ApiCtx, F)}};
                #{} ->
                    {IdxK, Val}
            end;
        InvalidEvent ->
            {error, #{
                reason => corrupted_event,
                expected_event => {ScheduledEventId, 'EVENT_TYPE_ACTIVITY_TASK_SCHEDULED'},
                received_event => InvalidEvent
            }}
    end;
%% marker
from_event(
    EventId,
    'EVENT_TYPE_MARKER_RECORDED',
    #{marker_name := Name} = Event,
    HistoryTable,
    ApiCtx
) ->
    MN = 'temporal.api.history.v1.MarkerRecordedEventAttributes',
    Details = temporal_sdk_api:map_from_mapstring_payloads(
        ApiCtx, MN, details, maps:get(details, Event, #{})
    ),
    Value =
        case Details of
            #{"value" := V} -> V;
            #{~"value" := V} -> V;
            #{} -> []
        end,
    {_UsrHdr, #{type := Type, decoder := Decoder, mutable := Mutable}} =
        temporal_sdk_api_header:get_sdk(
            #{type => ?DEFAULT_MARKER_TYPE, mutable => false, decoder => none}, Event, MN, ApiCtx
        ),
    DecodedValue = temporal_sdk_api_common:marker_decode_value(Decoder, Value),
    Data1 = #{state => recorded, event_id => EventId, value => DecodedValue},
    Data =
        case Mutable of
            #{mutations_limit := L} when L > 0 ->
                ResetReason = temporal_sdk_api_common:mutation_reset_reason(Name),
                MutationsCount = temporal_sdk_api_awaitable_history_table:mutations_count(
                    HistoryTable, ResetReason
                ),
                Data1#{mutations_count => MutationsCount};
            _ ->
                Data1
        end,
    case Type =:= "message" orelse Type =:= ~"message" of
        true ->
            {{marker, Type, Name}, Data};
        false ->
            {{marker, Type, Name}, Data#{
                details => maps:without(["type", ~"type", "value", ~"value"], Details)
            }}
    end;
%% timer
from_event(
    EventId,
    'EVENT_TYPE_TIMER_STARTED',
    #{timer_id := Id},
    _HistoryTable,
    _ApiCtx
) ->
    {
        {timer, Id},
        #{
            state => started,
            event_id => EventId
        }
    };
from_event(
    EventId,
    'EVENT_TYPE_TIMER_FIRED',
    #{timer_id := Id, started_event_id := StartedEventId},
    _HistoryTable,
    _ApiCtx
) ->
    {
        {timer, Id},
        #{
            state => fired,
            event_id => EventId,
            started_event_id => StartedEventId
        }
    };
from_event(
    EventId,
    'EVENT_TYPE_TIMER_CANCELED',
    #{timer_id := Id, started_event_id := StartedEventId},
    _HistoryTable,
    _ApiCtx
) ->
    {
        {timer, Id},
        #{
            state => canceled,
            event_id => EventId,
            started_event_id => StartedEventId
        }
    };
%% child_workflow
from_event(
    EventId,
    'EVENT_TYPE_START_CHILD_WORKFLOW_EXECUTION_INITIATED',
    #{workflow_id := WId},
    _HistoryTable,
    _ApiCtx
) ->
    {{child_workflow, WId}, #{state => initiated, event_id => EventId}};
from_event(
    EventId,
    'EVENT_TYPE_START_CHILD_WORKFLOW_EXECUTION_FAILED',
    #{workflow_id := WId} = Attr,
    _HistoryTable,
    _ApiCtx
) ->
    IV = maps:with([cause, initiated_event_id], Attr),
    {{child_workflow, WId}, IV#{state => initiate_failed, event_id => EventId}};
from_event(
    EventId,
    'EVENT_TYPE_CHILD_WORKFLOW_EXECUTION_STARTED',
    #{workflow_execution := #{workflow_id := WId, run_id := RId}} = Attr,
    _HistoryTable,
    _ApiCtx
) ->
    IV = maps:with([initiated_event_id], Attr),
    {{child_workflow, WId}, IV#{state => started, event_id => EventId, run_id => RId}};
from_event(
    EventId,
    'EVENT_TYPE_CHILD_WORKFLOW_EXECUTION_COMPLETED',
    #{workflow_execution := #{workflow_id := WId}} = Attr,
    _HistoryTable,
    ApiCtx
) ->
    MN = 'temporal.api.history.v1.ChildWorkflowExecutionCompletedEventAttributes',
    IV0 = maps:with([started_event_id], Attr),
    IV =
        case Attr of
            #{result := V} ->
                IV0#{result => temporal_sdk_api:map_from_payloads(ApiCtx, MN, result, V)};
            #{} ->
                IV0#{result => []}
        end,
    {{child_workflow, WId}, IV#{state => completed, event_id => EventId}};
from_event(
    EventId,
    'EVENT_TYPE_CHILD_WORKFLOW_EXECUTION_FAILED',
    #{workflow_execution := #{workflow_id := WId}} = Attr,
    _HistoryTable,
    ApiCtx
) ->
    IV1 = maps:with([started_event_id], Attr),
    IV =
        case Attr of
            #{failure := F} -> IV1#{failure => temporal_sdk_api_failure:from_temporal(ApiCtx, F)};
            #{} -> IV1
        end,
    {{child_workflow, WId}, IV#{state => failed, event_id => EventId}};
from_event(
    EventId,
    'EVENT_TYPE_CHILD_WORKFLOW_EXECUTION_CANCELED',
    #{workflow_execution := #{workflow_id := WId}} = Attr,
    _HistoryTable,
    ApiCtx
) ->
    MN = 'temporal.api.history.v1.ChildWorkflowExecutionCanceledEventAttributes',
    IV0 = maps:with([started_event_id], Attr),
    IV =
        case Attr of
            #{details := V} ->
                IV0#{details => temporal_sdk_api:map_from_payloads(ApiCtx, MN, details, V)};
            #{} ->
                IV0#{details => []}
        end,
    {{child_workflow, WId}, IV#{state => canceled, event_id => EventId}};
from_event(
    EventId,
    'EVENT_TYPE_CHILD_WORKFLOW_EXECUTION_TIMED_OUT',
    #{workflow_execution := #{workflow_id := WId}} = Attr,
    _HistoryTable,
    _ApiCtx
) ->
    IV = maps:with([started_event_id, retry_state], Attr),
    {{child_workflow, WId}, IV#{state => timedout, event_id => EventId}};
from_event(
    EventId,
    'EVENT_TYPE_CHILD_WORKFLOW_EXECUTION_TERMINATED',
    #{workflow_execution := #{workflow_id := WId}} = Attr,
    _HistoryTable,
    _ApiCtx
) ->
    IV = maps:with([started_event_id], Attr),
    {{child_workflow, WId}, IV#{state => terminated, event_id => EventId}};
%% signal
from_event(
    EventId,
    'EVENT_TYPE_WORKFLOW_EXECUTION_SIGNALED',
    #{signal_name := SN, identity := Idt} = T,
    _HistoryTable,
    ApiCtx
) ->
    MN = 'temporal.api.history.v1.WorkflowExecutionSignaledEventAttributes',
    {Data0, #{}} = temporal_sdk_api_header:get_sdk(#{}, T, MN, ApiCtx),
    I = maps:get(input, T, ?DEFAULT_PAYLOADS),
    Data1 = Data0#{
        state => requested,
        event_id => EventId,
        input => temporal_sdk_api:map_from_payloads(ApiCtx, MN, input, I),
        identity => Idt
    },
    Data =
        case T of
            #{external_workflow_execution := EWE} -> Data1#{external_workflow_execution => EWE};
            #{} -> Data1
        end,
    {{signal, SN}, Data};
%% workflow_properties
from_event(
    EventId,
    'EVENT_TYPE_WORKFLOW_PROPERTIES_MODIFIED',
    #{upserted_memo := #{fields := Memo}},
    _HistoryTable,
    ApiCtx
) ->
    MN = 'temporal.api.history.v1.WorkflowPropertiesModifiedEventAttributes',
    {
        {workflow_properties},
        #{
            state => modified,
            event_id => EventId,
            upserted_memo => temporal_sdk_api:map_from_mapstring_payload(
                ApiCtx, MN, [upserted_memo, fields], Memo
            )
        }
    };
%% cancel_workflow_execution_request
from_event(
    EventId,
    'EVENT_TYPE_WORKFLOW_EXECUTION_CANCEL_REQUESTED',
    #{} = Task,
    _HistoryTable,
    _ApiCtx
) ->
    %% MN = 'temporal.api.history.v1.WorkflowExecutionCancelRequestedEventAttributes',
    {
        {cancel_request},
        Task#{state => requested, event_id => EventId}
    };
%% closing events
from_event(
    EventId,
    'EVENT_TYPE_WORKFLOW_EXECUTION_COMPLETED',
    #{result := R},
    _HistoryTable,
    ApiCtx
) ->
    MN = 'temporal.api.history.v1.WorkflowExecutionCompletedEventAttributes',
    {{complete_workflow_execution}, #{
        state => completed,
        result => temporal_sdk_api:map_from_payloads(ApiCtx, MN, result, R),
        event_id => EventId
    }};
from_event(
    EventId,
    'EVENT_TYPE_WORKFLOW_EXECUTION_CANCELED',
    #{details := D},
    _HistoryTable,
    ApiCtx
) ->
    MN = 'temporal.api.history.v1.WorkflowExecutionCanceledEventAttributes',
    {{cancel_workflow_execution}, #{
        state => canceled,
        details => temporal_sdk_api:map_from_payloads(ApiCtx, MN, details, D),
        event_id => EventId
    }};
from_event(
    EventId,
    'EVENT_TYPE_WORKFLOW_EXECUTION_FAILED',
    #{failure := Failure},
    _HistoryTable,
    ApiCtx
) ->
    F1 = temporal_sdk_api_failure:from_temporal(ApiCtx, Failure),
    {{fail_workflow_execution}, #{state => failed, event_id => EventId, failure => F1}};
from_event(
    EventId,
    'EVENT_TYPE_WORKFLOW_EXECUTION_CONTINUED_AS_NEW',
    #{},
    _HistoryTable,
    _ApiCtx
) ->
    {{continue_as_new_workflow}, #{state => continued, event_id => EventId}};
%% ignored event
from_event(_EventId, _EventType, _EventAttr, _HistoryTable, _ApiCtx) ->
    ignore_index.

do_select_by_id(Table, EventId) ->
    case ets:select_reverse(Table, [{{EventId, '_', '_', '_'}, [], ['$_']}], 1) of
        {[{EventId, EventType, Attr, _Data}], _} -> {EventId, EventType, Attr};
        '$end_of_table' -> noevent
    end.

-spec from_poll(
    PolledTask :: ?TEMPORAL_SPEC:'temporal.api.query.v1.WorkflowQuery'(),
    ApiCtx :: temporal_sdk_api:context()
) -> tuple().
from_poll(#{query_type := QueryType} = Query, ApiCtx) ->
    MN = 'temporal.api.workflowservice.v1.PollWorkflowTaskQueueResponse',
    Q1 =
        case Query of
            #{query_args := QA} ->
                #{
                    query_args => temporal_sdk_api:map_from_payloads(
                        ApiCtx, MN, [query, query_args], QA
                    )
                };
            #{} ->
                #{}
        end,
    Q2 =
        case Query of
            #{header := #{fields := HF}} ->
                Q1#{
                    header => temporal_sdk_api:map_from_mapstring_payload(
                        ApiCtx, MN, [query, header, fields], HF
                    )
                };
            #{} ->
                Q1
        end,
    {{query, QueryType}, Q2#{state => requested}}.
