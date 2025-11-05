-module(temporal_sdk_api_awaitable_history_table).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    insert_new/2,
    fetch/2,
    mutations_count/2,
    reset_event_id/1,
    append/5
]).

-include("proto.hrl").

-spec insert_new(
    Table :: ets:table(),
    EventOrEvents :: temporal_sdk_workflow:history_event() | [temporal_sdk_workflow:history_event()]
) ->
    ok | {Error :: term(), Reason :: map()}.
insert_new(Table, EventOrEvents) ->
    maybe
        ok ?= insert_new_check(ets:last(Table), EventOrEvents),
        true ?= ets:insert_new(Table, EventOrEvents),
        ok
    else
        false -> {"Duplicate history table event(s).", #{new_events => EventOrEvents}};
        Err -> Err
    end.

insert_new_check('$end_of_table', {1, _, _, _}) ->
    ok;
insert_new_check('$end_of_table', [{1, _, _, _} | _]) ->
    ok;
insert_new_check('$end_of_table', EventOrEvents) ->
    {"Missing history table event(s).", #{new_events => EventOrEvents}};
insert_new_check(LastEventId, {EventId, _, _, _}) when LastEventId + 1 =:= EventId ->
    ok;
insert_new_check(LastEventId, [{EventId, _, _, _} | _]) when LastEventId + 1 =:= EventId ->
    ok;
insert_new_check(LastEventId, EventOrEvents) ->
    {"Invalid history table event_id.", #{
        received_events => EventOrEvents, last_event_id => LastEventId
    }}.

-spec fetch(Table :: ets:table(), Pattern :: temporal_sdk_workflow:history_event_pattern()) ->
    EventData :: temporal_sdk_workflow:event_data() | noevent.
fetch(Table, Pattern) ->
    case ets:select_reverse(Table, [{Pattern, [], ['$_']}], 1) of
        {[{EventId, Type, Attr, Data}], _} ->
            #{event_id => EventId, type => Type, attributes => Attr, data => Data};
        '$end_of_table' ->
            noevent
    end.

-spec mutations_count(
    HistoryTable :: ets:table(), {ResetReasonStr :: string(), ResetReasonBin :: binary()}
) -> non_neg_integer().
mutations_count(HistoryTable, {ResetReasonStr, ResetReasonBin}) ->
    ets:select_count(HistoryTable, [
        {
            {'_', 'EVENT_TYPE_WORKFLOW_TASK_FAILED',
                #{
                    cause => 'WORKFLOW_TASK_FAILED_CAUSE_RESET_WORKFLOW',
                    failure => #{message => '$1'}
                },
                '_'},
            [{'orelse', {'=:=', '$1', ResetReasonStr}, {'=:=', '$1', ResetReasonBin}}],
            [true]
        }
    ]).

-spec reset_event_id(HistoryTable :: ets:table()) -> pos_integer().
reset_event_id(HistoryTable) ->
    case
        ets:select_reverse(
            HistoryTable,
            [
                {
                    {'$1', '$2', '_', '_'},
                    [
                        {'orelse', {'=:=', '$2', 'EVENT_TYPE_WORKFLOW_TASK_COMPLETED'},
                            {'=:=', '$2', 'EVENT_TYPE_WORKFLOW_TASK_STARTED'},
                            {'=:=', '$2', 'EVENT_TYPE_WORKFLOW_TASK_FAILED'},
                            {'=:=', '$2', 'EVENT_TYPE_WORKFLOW_TASK_TIMED_OUT'}}
                    ],
                    ['$1']
                }
            ],
            1
        )
    of
        {[EventId], _Continuation} when is_integer(EventId) -> EventId;
        '$end_of_table' -> 3
    end.

-spec append(
    AppendType :: sticky | regular | get,
    EventId :: pos_integer(),
    HistoryEvents :: [temporal_sdk_workflow:history_event()],
    TemporalHistoryEvents :: [?TEMPORAL_SPEC:'temporal.api.history.v1.HistoryEvent'()],
    HistoryTable :: ets:table()
) ->
    {ok, [temporal_sdk_workflow:history_event()]} | {error, Reason :: map()}.
append(_AppendType, _EventId, HistoryEvents, [], _HistoryTable) ->
    {ok, HistoryEvents};
append(
    AppendType,
    EventId,
    HistoryEvents,
    [#{event_id := TEId} | _] = TemporalHistoryEvents,
    HistoryTable
) ->
    LastEId = last_history_event_id(HistoryEvents, EventId),
    maybe
        ok ?= check_id(AppendType, LastEId, TEId),
        {ok, [{THEEid, _, _, _} | _] = THE} ?=
            temporal_sdk_api_awaitable_history:temporal_to_history(TemporalHistoryEvents),
        {ok, NewHE} ?= check_events(EventId, LastEId, THEEid, HistoryEvents, THE, HistoryTable),
        {ok, HistoryEvents ++ NewHE}
    else
        {error, Reason} ->
            {error, Reason#{corrupted_event_source => corrupted_event_source(AppendType)}}
    end.

corrupted_event_source(sticky) ->
    "PollWorkflowTaskQueueResponse from sticky task queue or RespondWorkflowTaskCompletedResponse";
corrupted_event_source(regular) ->
    "PollWorkflowTaskQueueResponse from regular task queue";
corrupted_event_source(get) ->
    "GetWorkflowExecutionHistoryResponse".

check_id(sticky, EId, TEId) when EId =:= TEId ->
    ok;
check_id(regular, _EId, 1) ->
    ok;
check_id(get, EId, TEId) when EId >= TEId ->
    ok;
check_id(_AppendType, EId, TEId) ->
    {error, #{
        reason => corrupted_history,
        expected_event_id => EId,
        received_event_id => TEId
    }}.

check_events(_TblEnd, EId, EId, _HistoryEvents, TemporalHistoryEvents, _HistoryTable) ->
    {ok, TemporalHistoryEvents};
check_events(TblEnd, HisEnd, TmpStart, HistoryEvents, TemporalHistoryEvents, HistoryTable) ->
    {TmpEnd, _, _, _} = lists:last(TemporalHistoryEvents),
    HisStart =
        case HistoryEvents of
            [] -> HisEnd;
            [{HS, _, _, _} | _] -> HS
        end,
    TableEvents =
        case HistoryTable of
            undefined ->
                [];
            _ ->
                case TmpStart < TblEnd of
                    false ->
                        [];
                    true ->
                        ets:select(HistoryTable, [
                            {
                                {'$1', '_', '_', '_'},
                                [{'andalso', {'>=', '$1', TmpStart}, {'=<', '$1', TmpEnd}}],
                                ['$_']
                            }
                        ])
                end
        end,
    ListEvents =
        case TmpStart > HisEnd orelse TmpEnd < HisStart of
            true ->
                [];
            false ->
                Fn = fun
                    ({EId, _, _, _}) when EId >= TmpStart, EId =< TmpEnd -> true;
                    (_) -> false
                end,
                lists:filter(Fn, HistoryEvents)
        end,
    LocalEvents = TableEvents ++ ListEvents,
    {ExistingTHE, NewTHE} =
        case TmpEnd < HisEnd of
            true ->
                {TemporalHistoryEvents, []};
            false ->
                case TmpStart > HisEnd of
                    true ->
                        {[], TemporalHistoryEvents};
                    false ->
                        lists:split(HisEnd - TmpStart, TemporalHistoryEvents)
                end
        end,
    case temporal_sdk_api_awaitable_history:compare_events(LocalEvents, ExistingTHE) of
        ok -> {ok, NewTHE};
        Err -> Err
    end.

last_history_event_id([], EventId) ->
    EventId;
last_history_event_id(HistoryEvents, EventId) ->
    case lists:last(HistoryEvents) of
        {Id, _, _, _} when is_integer(Id) -> Id + 1;
        _ -> EventId
    end.
