-module(temporal_sdk_api_awaitable_index_table).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    upsert_and_count/2,
    upsert_index/2,
    upsert_polled/3,
    upsert_cancelation/2,
    update_cancelation/3,
    fetch/2
]).

-spec upsert_and_count(
    Table :: ets:table(), Index :: temporal_sdk_workflow:awaitable_index() | ignore_index
) ->
    {ok, TemporalOpenTasksCount :: integer()} | {error, Reason :: map()}.
upsert_and_count(_Table, ignore_index) ->
    {ok, 0};
upsert_and_count(Table, {{info, _}, _} = Index) ->
    ets:insert(Table, Index),
    {ok, 0};
upsert_and_count(Table, {{marker, Type, _}, _} = Index) when
    Type =:= "message"; Type =:= ~"message"
->
    ets:insert(Table, Index),
    {ok, 0};
upsert_and_count(Table, {IndexKey, NewIndexValue}) when is_tuple(IndexKey) ->
    OldIndexValue = fetch(Table, IndexKey),
    A = element(1, IndexKey),
    case temporal_sdk_api_awaitable_index:transit(A, OldIndexValue, NewIndexValue) of
        invalid ->
            Reason =
                case {NewIndexValue, OldIndexValue} of
                    {#{state := cmd}, #{state := _}} -> "Duplicate awaitable id is not allowed.";
                    _ -> "Invalid awaitable state transition."
                end,
            {error, #{
                reason => Reason,
                awaitable => IndexKey,
                new_awaitable_data => NewIndexValue,
                old_awaitable_data => OldIndexValue
            }};
        Count ->
            IVal = temporal_sdk_api_awaitable_index:merge_data(A, OldIndexValue, NewIndexValue),
            ets:insert(Table, {IndexKey, IVal}),
            {ok, Count}
    end;
upsert_and_count(_Table, {IndexKey, IndexValue}) ->
    {error, #{
        reason => "Malformed index table upsert command.",
        awaitable => IndexKey,
        awaitable_data => IndexValue
    }}.

-spec upsert_index(IndexTable :: ets:table(), Index :: temporal_sdk_workflow:awaitable_index()) ->
    ok | {error, Reason :: map()}.
upsert_index(IndexTable, Index) ->
    case upsert_and_count(IndexTable, Index) of
        {ok, 0} ->
            ok;
        {ok, UC} ->
            {error, #{reason => "Invalid awaitable state.", awaitable => Index, upsert_count => UC}};
        Err ->
            Err
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
    case upsert_index(IndexTable, {IdxKey, IdxVal#{'_sdk_data' => {token, TaskToken}}}) of
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
    case upsert_index(IndexTable, {IdxKey, IdxVal#{'_sdk_data' => {id, QId}}}) of
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
    case fetch(IndexTable, CancelationIndexKey) of
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
                    % eqwalizer:ignore
                    Idx = {CancelationIndexKey, IdxVal#{cancel_requested => true}},
                    case upsert_and_count(IndexTable, Idx) of
                        {ok, 0} ->
                            % eqwalizer:ignore
                            {ok, ScheduledEventId, IdxVal};
                        {ok, UC} ->
                            {error, #{
                                reason => "Invalid awaitable state.",
                                awaitable => Idx,
                                upsert_count => UC
                            }};
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
    case fetch(IndexTable, IdxKey) of
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
fetch(Table, IndexKey) ->
    case ets:match(Table, {IndexKey, '$1'}, 1) of
        {[[Match]], _} -> Match;
        '$end_of_table' -> noevent
    end.
