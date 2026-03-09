-module(temporal_sdk_api_awaitable_index_table).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    upsert_cmd/2,
    upsert_event/2,
    upsert_ext/2,
    update_event_id/3,
    upsert_polled/3,
    upsert_cancelation/2,
    update_cancelation/3,
    fetch/2,
    respond_queries/7
]).

-spec upsert_cmd(IndexTable :: ets:table(), Index :: temporal_sdk_workflow:awaitable_index()) ->
    ok | {error, Reason :: map()}.
upsert_cmd(IndexTable, {IndexKey, NewIndexVal}) ->
    OldIndexVal = match_by_idx(IndexTable, IndexKey),
    A = element(1, IndexKey),
    case temporal_sdk_api_awaitable_index:tstc(A, OldIndexVal, NewIndexVal) of
        invalid ->
            {error, #{
                reason => nondeterministic,
                details => "Invalid awaitable command state transition.",
                awaitable => IndexKey,
                new_awaitable_data => NewIndexVal,
                old_awaitable_data => OldIndexVal
            }};
        0 ->
            IVal = temporal_sdk_api_awaitable_index:merge_data_cmd(A, OldIndexVal, NewIndexVal),
            ets:insert(IndexTable, {IndexKey, IVal}),
            ok
    end.

-spec upsert_event(
    IndexTable :: ets:table(), Index :: temporal_sdk_workflow:awaitable_index() | ignore_index
) ->
    {ok, TemporalOpenTasksCount :: integer()} | {error, Reason :: map()}.
upsert_event(_IndexTable, ignore_index) ->
    {ok, 0};
upsert_event(IndexTable, {{signal, _}, _} = Index) ->
    upsert_event_noncmd(IndexTable, Index);
upsert_event(IndexTable, {{marker, MT, _}, _} = Index) when MT =:= ~"message"; MT =:= "message" ->
    upsert_event_noncmd(IndexTable, Index);
upsert_event(IndexTable, {{cancel_request}, _} = Index) ->
    upsert_event_noncmd(IndexTable, Index);
upsert_event(IndexTable, {IndexKey, NewIndexVal} = Index) ->
    case fetch_by_event(IndexTable, Index) of
        {NewIndexKey, OldIndexVal} ->
            A = element(1, IndexKey),
            case temporal_sdk_api_awaitable_index:tste(A, OldIndexVal, NewIndexVal) of
                invalid ->
                    {error, #{
                        reason => nondeterministic,
                        details => "Invalid awaitable event state transition.",
                        awaitable => IndexKey,
                        new_awaitable_data => NewIndexVal,
                        old_awaitable_data => OldIndexVal
                    }};
                Count ->
                    IVal = temporal_sdk_api_awaitable_index:merge_data_event(
                        A, OldIndexVal, NewIndexVal
                    ),
                    ets:insert(IndexTable, {NewIndexKey, IVal}),
                    {ok, Count}
            end;
        Err ->
            {error, #{
                reason => nondeterministic,
                details => "Invalid awaitable.",
                awaitable => IndexKey,
                new_awaitable_data => NewIndexVal,
                old_awaitable_data => Err
            }}
    end.

upsert_event_noncmd(IndexTable, {IndexKey, NewIndexVal}) ->
    OldIndexVal = match_by_idx(IndexTable, IndexKey),
    A = element(1, IndexKey),
    case temporal_sdk_api_awaitable_index:tstn(A, OldIndexVal, NewIndexVal) of
        invalid ->
            {error, #{
                reason => nondeterministic,
                details => "Invalid awaitable not commanded event state transition.",
                awaitable => IndexKey,
                new_awaitable_data => NewIndexVal,
                old_awaitable_data => OldIndexVal
            }};
        0 ->
            IVal = temporal_sdk_api_awaitable_index:merge_data_event_nocmd(
                A, OldIndexVal, NewIndexVal
            ),
            ets:insert(IndexTable, {IndexKey, IVal}),
            {ok, 0}
    end.

-spec upsert_ext(IndexTable :: ets:table(), Index :: temporal_sdk_workflow:awaitable_index()) ->
    ok | {error, Reason :: map()}.
upsert_ext(IndexTable, {IndexKey, NewIndexVal}) ->
    OldIndexVal = match_by_idx(IndexTable, IndexKey),
    A = element(1, IndexKey),
    case temporal_sdk_api_awaitable_index:tstx(A, OldIndexVal, NewIndexVal) of
        invalid ->
            {error, #{
                reason => nondeterministic,
                details => "Invalid external awaitable state transition.",
                awaitable => IndexKey,
                new_awaitable_data => NewIndexVal,
                old_awaitable_data => OldIndexVal
            }};
        0 ->
            IVal = temporal_sdk_api_awaitable_index:merge_data_ext(A, OldIndexVal, NewIndexVal),
            ets:insert(IndexTable, {IndexKey, IVal}),
            ok
    end.

-spec update_event_id(
    IndexTable :: ets:table(),
    Index :: temporal_sdk_workflow:awaitable_index(),
    EventId :: pos_integer()
) -> {ok, temporal_sdk_workflow:awaitable_index()} | {error, Reason :: map()}.
update_event_id(IndexTable, {IndexKey, IndexVal}, EventId) ->
    case match_by_idx(IndexTable, IndexKey) of
        noevent ->
            {error, #{
                reason => nondeterministic,
                details => "Required awaitable not found.",
                awaitable => IndexKey,
                new_awaitable_event_id => EventId,
                awaitable_data => noevent
            }};
        OldIdxVal ->
            A = element(1, IndexKey),
            IVal = temporal_sdk_api_awaitable_index:merge_data_event_id(
                A, EventId, OldIdxVal, IndexVal
            ),
            ets:insert(IndexTable, {IndexKey, IVal}),
            % eqwalizer:ignore
            {ok, {IndexKey, IVal}}
    end.

-spec upsert_polled(
    IndexTable :: ets:table(),
    Task :: temporal_sdk_workflow:task(),
    ApiCtx :: temporal_sdk_api:context()
) -> {ok, HasUpsertedEvents :: boolean()} | {error, Reason :: map()}.
upsert_polled(IndexTable, Task, ApiCtx) ->
    maybe
        {ok, HasQ} ?= do_upsert_query(Task, ApiCtx, IndexTable),
        {ok, HasQS} ?= do_upsert_queries(Task, ApiCtx, IndexTable),
        {ok, HasM} ?= do_upsert_messages(Task, ApiCtx, IndexTable),
        {ok, HasQ orelse HasM orelse HasQS}
    end.

do_upsert_query(#{task_token := TaskToken, query := Query}, ApiCtx, IndexTable) ->
    {IdxKey, IdxVal} = temporal_sdk_api_awaitable_index:from_poll(Query, ApiCtx),
    case upsert_ext(IndexTable, {IdxKey, IdxVal#{'_sdk_data' => {token, TaskToken}}}) of
        ok -> {ok, true};
        Err -> Err
    end;
do_upsert_query(#{}, _ApiCtx, _IndexTable) ->
    {ok, false}.

do_upsert_queries(#{queries := Queries}, ApiCtx, IndexTable) when map_size(Queries) > 0 ->
    do_upqs(maps:to_list(Queries), ApiCtx, IndexTable);
do_upsert_queries(#{}, _ApiCtx, _IndexTable) ->
    {ok, false}.

do_upqs([{QId, Query} | TQueries], ApiCtx, IndexTable) ->
    {IdxKey, IdxVal} = temporal_sdk_api_awaitable_index:from_poll(Query, ApiCtx),
    case upsert_ext(IndexTable, {IdxKey, IdxVal#{'_sdk_data' => {id, QId}}}) of
        ok -> do_upqs(TQueries, ApiCtx, IndexTable);
        Err -> Err
    end;
do_upqs([], _ApiCtx, _IndexTable) ->
    {ok, true}.

do_upsert_messages(#{messages := [_ | _] = _Messages}, _ApiCtx, _IndexTable) ->
    {error, "Workflow execution updates are not supported yet."};
do_upsert_messages(#{}, _ApiCtx, _IndexTable) ->
    {ok, false}.

-spec upsert_cancelation(
    IndexTable :: ets:table(),
    CancelationIndexKey ::
        temporal_sdk_workflow:activity_index_key()
        | temporal_sdk_workflow:nexus_index_key()
        | temporal_sdk_workflow:timer_index_key()
) ->
    {ok, ScheduledEventId :: pos_integer(),
        temporal_sdk_workflow:activity_data()
        | temporal_sdk_workflow:nexus_data()
        | temporal_sdk_workflow:timer_data()}
    | {error, Reason :: map()}.
upsert_cancelation(IndexTable, CancelationIndexKey) ->
    case match_by_idx(IndexTable, CancelationIndexKey) of
        noevent ->
            {error, #{
                reason => "Awaitable that wasn't started cannot be canceled.",
                awaitable => CancelationIndexKey
            }};
        #{cancel_requested := true} ->
            {error, #{
                reason => "Duplicate cancel awaitable request.",
                awaitable => CancelationIndexKey
            }};
        IdxVal ->
            case do_fetch_scheduled_id(CancelationIndexKey, IdxVal) of
                {ok, ScheduledEventId} ->
                    Idx = {CancelationIndexKey, IdxVal#{cancel_requested => true}},
                    case upsert_cmd(IndexTable, Idx) of
                        ok ->
                            {ok, ScheduledEventId, IdxVal};
                        Err ->
                            Err
                    end;
                {error, Reason} ->
                    {error, #{reason => Reason, awaitable => CancelationIndexKey}}
            end
    end.

-spec update_cancelation(
    IndexTable :: ets:table(),
    CancelationIndexCommand ::
        {
            {temporal_sdk_workflow:activity_index_key(), temporal_sdk_workflow:activity_data()},
            temporal_sdk_api_command:command()
        }
        | {
            {temporal_sdk_workflow:nexus_index_key(), temporal_sdk_workflow:nexus_data()},
            temporal_sdk_api_command:command()
        },
    EventId :: pos_integer()
) ->
    {ok,
        UpdatedCancelationIndexCommand ::
            {
                {temporal_sdk_workflow:activity_index_key(), temporal_sdk_workflow:activity_data()},
                temporal_sdk_api_command:command()
            }
            | {
                {temporal_sdk_workflow:nexus_index_key(), temporal_sdk_workflow:nexus_data()},
                temporal_sdk_api_command:command()
            }}
    | {error, Reason :: map()}.
update_cancelation(IndexTable, {{IdxKey, _IdxVal}, Cmd}, EventId) ->
    case match_by_idx(IndexTable, IdxKey) of
        #{cancel_requested := true} = IV ->
            case do_fetch_scheduled_id(IdxKey, IV) of
                {ok, SEId} ->
                    #{attributes := {Req, Attr}} = Cmd,
                    NCmd = Cmd#{attributes := {Req, Attr#{scheduled_event_id := SEId}}},
                    % eqwalizer:ignore
                    {ok, {
                        {IdxKey, #{state => cmd, cancel_requested => true, event_id => EventId + 1}},
                        NCmd
                    }};
                Err ->
                    Err
            end;
        IV ->
            {error, #{
                reason =>
                    "Malformed cancelation update flow. Expected canceled awaitable, received invalid.",
                awaitable => IdxKey,
                invalid_awaitable_data => IV
            }}
    end.

do_fetch_scheduled_id({activity, _}, IdxVal) ->
    do_activity_seid(IdxVal);
do_fetch_scheduled_id({timer, _}, IdxVal) ->
    do_timer_seid(IdxVal).

do_activity_seid(#{state := S, event_id := EId, heartbeat_timeout := _}) when
    S =:= cmd; S =:= scheduled
->
    {ok, EId};
do_activity_seid(#{state := started, scheduled_event_id := EId, heartbeat_timeout := _}) ->
    {ok, EId};
do_activity_seid(#{state := completed, heartbeat_timeout := _}) ->
    {error, "Cannot cancel completed activity."};
do_activity_seid(#{state := canceled, heartbeat_timeout := _}) ->
    {error, "Cannot cancel canceled activity."};
do_activity_seid(#{state := completed}) ->
    {error, "Cannot cancel completed activity without <heartbeat_timeout>."};
do_activity_seid(#{state := canceled}) ->
    {error, "Cannot cancel canceled activity without <heartbeat_timeout>."};
do_activity_seid(_IdxVal) ->
    {error, "Cannot cancel activity without <heartbeat_timeout>."}.

do_timer_seid(#{state := fired}) -> {error, "Cannot cancel fired timer."};
do_timer_seid(#{event_id := EId}) -> {ok, EId}.

-spec fetch(Table :: ets:table(), IndexKey :: temporal_sdk_workflow:awaitable_index_key_pattern()) ->
    temporal_sdk_workflow:awaitable_index_data().
fetch(Table, IndexKey) -> match_by_idx(Table, IndexKey).

-spec respond_queries(
    Queries :: [term()],
    Query :: temporal_sdk_workflow:query_index_key(),
    QueryData :: {map(), map()},
    ApiContext :: temporal_sdk_api:context(),
    IndexTable :: ets:table(),
    HistoryAcc :: list(),
    QueriesAcc :: map()
) -> {ok, RespondedQueries :: map()} | {error, Reason :: map()}.
respond_queries(
    [#{state := requested, '_sdk_data' := {token, TT}} = QVal | TQueries],
    Query,
    {IdxVal, Response} = IVal,
    ApiContext,
    IndexTable,
    HistoryAcc,
    QueriesAcc
) ->
    temporal_sdk_api_workflow:respond_query_task_completed(ApiContext, Response#{task_token => TT}),
    Q1 = maps:without(['_sdk_data'], QVal),
    Q2 = maps:merge(Q1, IdxVal),
    NewHAcc = [Q2#{state := responded} | HistoryAcc],
    respond_queries(TQueries, Query, IVal, ApiContext, IndexTable, NewHAcc, QueriesAcc);
respond_queries(
    [#{state := requested, '_sdk_data' := {id, Id}} = QVal | TQueries],
    Query,
    {IdxVal, Response} = IVal,
    ApiContext,
    IndexTable,
    HistoryAcc,
    QueriesAcc
) ->
    Q1 = maps:without(['_sdk_data'], QVal),
    Q2 = maps:merge(Q1, IdxVal),
    NewHAcc = [Q2#{state := responded} | HistoryAcc],
    R =
        case Response of
            #{answer := _} -> Response#{result_type => 'QUERY_RESULT_TYPE_ANSWERED'};
            #{} -> Response#{result_type => 'QUERY_RESULT_TYPE_FAILED'}
        end,
    NewQAcc = QueriesAcc#{Id => R},
    respond_queries(TQueries, Query, IVal, ApiContext, IndexTable, NewHAcc, NewQAcc);
respond_queries(
    [#{state := responded} = QVal | TQueries],
    Query,
    IVal,
    ApiContext,
    IndexTable,
    HistoryAcc,
    QueriesAcc
) ->
    NewHAcc = [QVal | HistoryAcc],
    respond_queries(TQueries, Query, IVal, ApiContext, IndexTable, NewHAcc, QueriesAcc);
respond_queries(
    [],
    Query,
    _IVal,
    _ApiContext,
    IndexTable,
    HistoryAcc,
    QueriesAcc
) ->
    Idx =
        case lists:reverse(HistoryAcc) of
            [IVal] -> {Query, IVal};
            [IVal | HIVal] when is_map(IVal) -> {Query, IVal#{history => HIVal}}
        end,
    case upsert_ext(IndexTable, Idx) of
        ok -> {ok, QueriesAcc};
        Err -> Err
    end.

%% -------------------------------------------------------------------------------------------------
%% private

fetch_by_event(IndexTable, {IndexKey, IndexVal}) ->
    case match_by_idx(IndexTable, IndexKey) of
        noevent ->
            case IndexVal of
                #{event_id := EId} ->
                    case select_by_event_id(IndexTable, EId) of
                        noevent -> select_by_replay_id(IndexTable, tuple_to_list(IndexKey));
                        {IdxKey, IdxVal} -> {IdxKey, IdxVal#{replay_id => tuple_to_list(IndexKey)}}
                    end;
                #{} ->
                    noevent
            end;
        IdxVal ->
            {IndexKey, IdxVal}
    end.

match_by_idx(Table, IndexKey) ->
    case ets:match(Table, {IndexKey, '$1'}, 1) of
        {[[Match]], _} -> Match;
        '$end_of_table' -> noevent
    end.

select_by_event_id(T, EventId) ->
    case ets:select(T, [{{'$1', '$2'}, [{'=:=', EventId, {map_get, event_id, '$2'}}], ['$_']}]) of
        [{_, _} = Idx] -> Idx;
        [] -> noevent
    end.

select_by_replay_id(T, ReplayId) ->
    case ets:select(T, [{{'$1', '$2'}, [{'=:=', ReplayId, {map_get, replay_id, '$2'}}], ['$_']}]) of
        [{_, _} = Idx] -> Idx;
        [] -> noevent
    end.
