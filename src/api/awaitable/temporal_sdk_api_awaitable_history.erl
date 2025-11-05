-module(temporal_sdk_api_awaitable_history).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    history_to_index/3,
    update_workflow_info/2,
    compare_events/2,
    temporal_to_history/1
]).

-include("proto.hrl").

-define(IGNORED_WTS_EVENT_CHECK_KEYS, [identity, worker_version]).

-spec history_to_index(
    HistoryEvent :: temporal_sdk_workflow:history_event(),
    HistoryTable :: ets:table(),
    ApiContext :: temporal_sdk_api:context()
) ->
    {ok, ignore_index} | {ok, temporal_sdk_workflow:awaitable_index()} | {error, Reason :: term()}.
history_to_index(
    {_EventId, _EventType, _Attr, #{worker_may_ignore := true}}, _HistoryTable, _ApiContext
) ->
    {ok, ignore_index};
history_to_index({EventId, EventType, Attr, _Data}, HistoryTable, ApiContext) ->
    case
        temporal_sdk_api_awaitable_index:from_event(
            EventId, EventType, Attr, HistoryTable, ApiContext
        )
    of
        ignore_index -> {ok, ignore_index};
        {IKey, #{}} = R when is_tuple(IKey) -> {ok, R};
        Err -> Err
    end.

-spec update_workflow_info(
    temporal_sdk_workflow:history_event(), temporal_sdk_workflow:workflow_info()
) ->
    temporal_sdk_workflow:workflow_info().
update_workflow_info({_, 'EVENT_TYPE_WORKFLOW_TASK_SCHEDULED', #{attempt := A}, #{}}, WorkflowInfo) ->
    WorkflowInfo#{attempt := A};
update_workflow_info(
    {_, 'EVENT_TYPE_WORKFLOW_TASK_STARTED',
        #{suggest_continue_as_new := SCN, history_size_bytes := HS}, #{}},
    WorkflowInfo
) ->
    WorkflowInfo#{suggest_continue_as_new := SCN, history_size_bytes := HS};
update_workflow_info(_Event, WorkflowInfo) ->
    WorkflowInfo.

-spec compare_events(
    LocalEvents :: [temporal_sdk_workflow:history_event()],
    ReceivedEvents :: [temporal_sdk_workflow:history_event()]
) -> ok | {error, Reason :: map()}.
compare_events([E | TLocal], [E | TReceived]) ->
    compare_events(TLocal, TReceived);
compare_events(
    [{EId, 'EVENT_TYPE_WORKFLOW_TASK_STARTED', D1, R} = ELocal | TLocal],
    [{EId, 'EVENT_TYPE_WORKFLOW_TASK_STARTED', D2, R} = EReceived | TReceived]
) ->
    case
        maps:without(?IGNORED_WTS_EVENT_CHECK_KEYS, D1) =:=
            maps:without(?IGNORED_WTS_EVENT_CHECK_KEYS, D2)
    of
        true ->
            compare_events(TLocal, TReceived);
        false ->
            {error, #{
                reason => corrupted_history,
                expected_event => ELocal,
                received_event => EReceived
            }}
    end;
compare_events([ELocal | _], [EReceived | _]) ->
    {error, #{
        reason => corrupted_history,
        expected_event => ELocal,
        received_event => EReceived
    }};
compare_events([], [_ | _] = Received) ->
    {error, #{reason => corrupted_history, pending_events => Received}};
compare_events([_ | _] = Local, []) ->
    {error, #{reason => corrupted_history, missing_events => Local}};
compare_events([], []) ->
    ok.

-spec temporal_to_history(
    TemporalEvents :: [?TEMPORAL_SPEC:'temporal.api.history.v1.HistoryEvent'()]
) ->
    {ok, [temporal_sdk_workflow:history_event()]} | {error, Reason :: map()}.
temporal_to_history([#{event_id := EId} | _] = TemporalEvents) -> do_t2h(TemporalEvents, EId, []).

do_t2h(
    [
        #{
            event_id := EventId,
            event_time := EventTime,
            event_type := EventType,
            attributes := {_, Attributes}
        } = HEvent
        | THistoryEvents
    ],
    EventId,
    Acc
) ->
    %% version and task_id event keys seem to be abandoned in Temporal API
    Data = maps:without([event_id, event_time, event_type, attributes, version, task_id], HEvent),
    E =
        {EventId, EventType, Attributes, Data#{
            event_time => temporal_sdk_utils_time:protobuf_to_nanos(EventTime)
        }},
    do_t2h(THistoryEvents, EventId + 1, [E | Acc]);
do_t2h([#{event_id := EventId} | _THistoryEvents], ExpectedEventId, _Acc) ->
    {error, #{
        reason => corrupted_events_history,
        expected_event_id => ExpectedEventId,
        received_event_id => EventId
    }};
do_t2h([], _EventId, Acc) ->
    {ok, lists:reverse(Acc)}.
