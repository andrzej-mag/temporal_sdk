-module(temporal_sdk_api_awaitable).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    cast_key/2,
    init_match/2,
    match_test/2,
    is_ready/1,
    update_match/6,
    gen_idx/7,
    unblock_awaitable/4
]).

-spec cast_key(
    AwaitPattern :: temporal_sdk_workflow:await_pattern() | [temporal_sdk_workflow:await_pattern()],
    ApiCtx :: temporal_sdk_api:context()
) -> tuple().
cast_key({Operator, [P | TPattern]}, ApiContext) when Operator =:= one; Operator =:= all ->
    {H1, H2} = cast_key(P, ApiContext),
    {T1, T2} = cast_key(TPattern, ApiContext),
    {{Operator, [H1 | T1]}, {Operator, [H2 | T2]}};
cast_key([P | TPattern], ApiContext) ->
    {H1, H2} = cast_key(P, ApiContext),
    {T1, T2} = cast_key(TPattern, ApiContext),
    {[H1 | T1], [H2 | T2]};
cast_key([], _ApiContext) ->
    {[], []};
cast_key(#{state := _} = AwaitableData, _ApiContext) ->
    {awaitable_data, AwaitableData};
cast_key(Pattern, ApiContext) ->
    temporal_sdk_api_awaitable_index:cast_key(Pattern, ApiContext).

-spec init_match(AwaitPattern :: temporal_sdk_workflow:await_pattern(), {
    HistoryTable :: ets:table(), IndexTable :: ets:table()
}) -> temporal_sdk_workflow:await_match().
init_match({Operator, Pattern}, Tables) when Operator =:= one; Operator =:= all ->
    {Operator, [init_match(P, Tables) || P <- Pattern]};
init_match({event, HistoryEventPattern}, {HistoryTable, _IndexTable}) ->
    temporal_sdk_api_awaitable_history_table:fetch(HistoryTable, HistoryEventPattern);
init_match(#{state := _} = AwaitableData, {_HistoryTable, _IndexTable}) ->
    AwaitableData;
init_match(IndexKey, {_HistoryTable, IndexTable}) ->
    % eqwalizer:ignore
    temporal_sdk_api_awaitable_index_table:fetch(IndexTable, IndexKey).

match_test({Operator, Pattern}, {Operator, Match}) when Operator =:= one; Operator =:= all ->
    {Operator, lists:zipwith(fun(P, M) -> match_test(P, M) end, Pattern, Match)};
match_test(awaitable_data, _AwaitableData) ->
    {true, true};
match_test(Pattern, Match) ->
    A = element(1, Pattern),
    {
        temporal_sdk_api_awaitable_index:is_ready(A, Match),
        temporal_sdk_api_awaitable_index:is_closed(A, Match)
    }.

is_ready({one, [M | TMatches] = Matches}) ->
    case
        lists:member({true, false}, Matches) orelse lists:member({true, true}, Matches) orelse
            lists:member(true, Matches)
    of
        true ->
            true;
        false ->
            case M of
                {O, _} when O =:= one; O =:= all -> is_ready({one, [is_ready(M) | TMatches]});
                {_, _} -> is_ready({one, TMatches});
                false -> is_ready({one, TMatches})
            end
    end;
is_ready({one, []}) ->
    false;
is_ready({all, [M | TMatches] = Matches}) ->
    case lists:member({false, false}, Matches) orelse lists:member(false, Matches) of
        true ->
            false;
        false ->
            case M of
                {O, _} when O =:= one; O =:= all -> is_ready({all, [is_ready(M) | TMatches]});
                {_, _} -> is_ready({all, TMatches});
                true -> is_ready({all, TMatches})
            end
    end;
is_ready({all, []}) ->
    true;
is_ready({true, _}) ->
    true;
is_ready({false, _}) ->
    false.

update_match(Pattern, PatternKey, Match, Test, IndexTable, HistoryTable) ->
    case do_update(PatternKey, Match, Test, IndexTable, HistoryTable) of
        Match ->
            noop;
        NewMatch ->
            NewTest = match_test(Pattern, NewMatch),
            case is_ready(NewTest) of
                true -> {ready, NewMatch};
                false -> {update, NewMatch, NewTest}
            end
    end.

do_update({O, Pattern}, {O, Match}, {O, Test}, IT, HT) when O =:= one; O =:= all ->
    {O, lists:zipwith3(fun(P, M, T) -> do_update(P, M, T, IT, HT) end, Pattern, Match, Test)};
do_update(_Pattern, Match, {true, true}, _IndexTable, _HistoryTable) ->
    Match;
do_update({event, Pattern}, noevent, {false, false}, _IndexTable, HistoryTable) ->
    temporal_sdk_api_awaitable_history_table:fetch(HistoryTable, Pattern);
do_update(IndexKey, _Match, {_, false}, IndexTable, _HistoryTable) ->
    temporal_sdk_api_awaitable_index_table:fetch(IndexTable, IndexKey);
do_update(_Pattern, Match, {_, _}, _IndexTable, _HistoryTable) ->
    Match.

-spec gen_idx(
    OptsAttr :: map(),
    IndexKeyList :: list(),
    ExecutionId :: temporal_sdk_workflow:execution_id(),
    ACounter :: pos_integer(),
    Cmds :: [temporal_sdk_workflow:index_command()],
    ApiCtx :: temporal_sdk_api:context(),
    MsgName :: temporal_sdk_client:msg_name() | atom()
) ->
    {
        temporal_sdk_workflow:awaitable(),
        temporal_sdk_workflow:awaitable_index_key()
    }.
gen_idx(#{activity_id := Id} = OA, IndexKeyList, _EId, _ACounter, _Cmds, ApiCtx, _MName) when
    Id =/= "", Id =/= ~"", Id =/= ''
->
    do_gen_idx(Id, IndexKeyList, ApiCtx, OA);
gen_idx(#{marker_name := Id} = OA, IndexKeyList, _EId, _ACounter, _Cmds, ApiCtx, _MName) when
    Id =/= "", Id =/= ~"", Id =/= ''
->
    do_gen_idx(Id, IndexKeyList, ApiCtx, OA);
gen_idx(#{timer_id := Id} = OA, IndexKeyList, _EId, _ACounter, _Cmds, ApiCtx, _MName) when
    Id =/= "", Id =/= ~"", Id =/= ''
->
    do_gen_idx(Id, IndexKeyList, ApiCtx, OA);
gen_idx(#{workflow_id := Id} = OA, IndexKeyList, _EId, _ACounter, _Cmds, ApiCtx, _MName) when
    Id =/= "", Id =/= ~"", Id =/= ''
->
    do_gen_idx(Id, IndexKeyList, ApiCtx, OA);
% SDK
gen_idx(#{execution_id := Id} = OA, IndexKeyList, _EId, _ACounter, _Cmds, ApiCtx, _MName) when
    Id =/= "", Id =/= ~"", Id =/= ''
->
    do_gen_idx(Id, IndexKeyList, ApiCtx, OA);
gen_idx(#{info_id := Id} = OA, IndexKeyList, _EId, _ACounter, _Cmds, ApiCtx, _MName) when
    Id =/= "", Id =/= ~"", Id =/= ''
->
    do_gen_idx(Id, IndexKeyList, ApiCtx, OA);
gen_idx(#{awaitable_id := Opts} = OA, IndexKeyList, ExecutionId, ACounter, Cmds, ApiCtx, MName) when
    is_map(Opts)
->
    N1 =
        case Opts of
            #{id := Id} when Id =/= "", Id =/= ~"", Id =/= '' ->
                [temporal_sdk_api:serialize(ApiCtx, MName, id, Id)];
            #{} ->
                []
        end,
    N2 =
        case Opts of
            #{prefix := true} ->
                SerializedExecutionId =
                    temporal_sdk_api:serialize(ApiCtx, MName, id, ExecutionId),
                [SerializedExecutionId | [ACounter | N1]];
            #{prefix := false} ->
                N1;
            #{prefix := Pr} when Pr =/= "", Pr =/= ~"", Pr =/= '' -> [Pr | N1];
            #{} ->
                N1
        end,
    case N2 of
        [] ->
            erlang:error("Void awaitable id/name.", [
                OA,
                IndexKeyList,
                ExecutionId,
                ACounter,
                Cmds,
                ApiCtx,
                MName
            ]);
        _ ->
            ok
    end,
    case Opts of
        #{postfix := true} ->
            N = temporal_sdk_utils_path:string_path(N2) ++ "/",
            NCasted = temporal_sdk_api_awaitable_index:cast_value(hd(IndexKeyList), N, ApiCtx),
            IndexKeyListCasted = temporal_sdk_api_awaitable_index:cast_list(IndexKeyList, ApiCtx),
            NId = new_id(IndexKeyListCasted, NCasted, Cmds, ApiCtx),
            Idx = list_to_tuple(do_set_idx_event(OA, IndexKeyList) ++ [NId]),
            IdxCasted = list_to_tuple(IndexKeyListCasted ++ [NId]),
            {Idx, IdxCasted};
        #{postfix := Po} when Po =/= false, Po =/= "", Po =/= ~"", Po =/= '' ->
            NId = temporal_sdk_utils_path:string_path(
                N2 ++ [temporal_sdk_api:serialize(ApiCtx, MName, id, Po)]
            ),
            do_gen_idx(NId, IndexKeyList, ApiCtx, OA);
        #{} ->
            NId = temporal_sdk_utils_path:string_path(N2),
            do_gen_idx(NId, IndexKeyList, ApiCtx, OA)
    end;
gen_idx(#{awaitable_id := Id} = Opts, IndexKeyList, ExeId, ACounter, Cmds, ApiCtx, MName) ->
    gen_idx(
        Opts#{awaitable_id := #{prefix => true, postfix => true, id => Id}},
        IndexKeyList,
        ExeId,
        ACounter,
        Cmds,
        ApiCtx,
        MName
    ).

do_gen_idx(Id, IndexKeyList, ApiCtx, OptsAttr) ->
    IdCasted = temporal_sdk_api_awaitable_index:cast_value(hd(IndexKeyList), Id, ApiCtx),
    IndexKeyListCasted = temporal_sdk_api_awaitable_index:cast_list(IndexKeyList, ApiCtx),
    Idx = list_to_tuple(do_set_idx_event(OptsAttr, IndexKeyList) ++ [Id]),
    IdxCasted = list_to_tuple(IndexKeyListCasted ++ [IdCasted]),
    {Idx, IdxCasted}.

do_set_idx_event(#{awaitable_event := AE}, [A | TIdxKeyList]) ->
    AwaitableEvent = temporal_sdk_api_awaitable_index:to_event(A, AE),
    [AwaitableEvent | TIdxKeyList];
do_set_idx_event(#{}, IdxKeyList) ->
    IdxKeyList.

new_id(IKPrefix, NamePattern, Cmds, ApiCtx) ->
    Count = do_count_match(IKPrefix, NamePattern, Cmds),
    do_new_id(IKPrefix, NamePattern, Cmds, ApiCtx, Count).

do_new_id(IKPrefix, NamePattern, Cmds, ApiCtx, Count) ->
    NewName =
        case is_binary(NamePattern) of
            true ->
                C = integer_to_binary(Count),
                <<NamePattern/binary, C/binary>>;
            false ->
                NamePattern ++ integer_to_list(Count)
        end,
    case do_count_match(IKPrefix, NewName, Cmds) of
        0 -> NewName;
        _ -> do_new_id(IKPrefix, NamePattern, Cmds, ApiCtx, Count + 1)
    end.

do_count_match(IKPrefix, NamePattern, Cmds) ->
    lists:foldl(
        fun({{IK, _IV}, _C}, Acc) when is_integer(Acc) ->
            do_match_idx(IKPrefix, NamePattern, IK) + Acc
        end,
        0,
        Cmds
    ).

do_match_idx([A, T], P, {A, T, N}) -> do_match_name(P, N);
do_match_idx([A], P, {A, N}) -> do_match_name(P, N);
do_match_idx(_, _, _) -> 0.

do_match_name(P, N) when is_binary(P), is_binary(N) ->
    PSize = byte_size(P),
    case N of
        <<P:PSize/binary, _/binary>> -> 1;
        _ -> 0
    end;
do_match_name(P, N) when is_list(P), is_list(N) ->
    case lists:prefix(P, N) of
        true -> 1;
        false -> 0
    end.

-spec unblock_awaitable(
    Index :: {
        temporal_sdk_workflow:activity_index_key(), temporal_sdk_workflow:activity_data()
    },
    HistoryEvents :: [temporal_sdk_workflow:history_event()],
    ApiCtx :: temporal_sdk_api:context(),
    IndexTable :: ets:table()
) -> ok | noevent | {error, Reason :: map()}.
unblock_awaitable(
    {{activity, _} = IdxKey, #{direct_result := true, event_id := EId}},
    HistoryEvents,
    ApiCtx,
    IndexTable
) ->
    Fn = fun
        ({_, 'EVENT_TYPE_ACTIVITY_TASK_COMPLETED', #{scheduled_event_id := SEId}, _}) when
            SEId =:= EId
        ->
            true;
        ({_, 'EVENT_TYPE_ACTIVITY_TASK_CANCELED', #{scheduled_event_id := SEId}, _}) when
            SEId =:= EId
        ->
            true;
        (_) ->
            false
    end,
    case lists:search(Fn, HistoryEvents) of
        {value, {_, 'EVENT_TYPE_ACTIVITY_TASK_COMPLETED', #{result := Result}, _}} ->
            R = temporal_sdk_api:map_from_payloads(
                ApiCtx,
                'temporal.api.history.v1.ActivityTaskCompletedEventAttributes',
                result,
                Result
            ),
            Index = {IdxKey, #{result => R}},
            % eqwalizer:ignore
            temporal_sdk_api_awaitable_index_table:upsert_index(IndexTable, Index);
        {value, {_, 'EVENT_TYPE_ACTIVITY_TASK_COMPLETED', #{}, _}} ->
            R = temporal_sdk_api:map_from_payloads(
                ApiCtx,
                'temporal.api.history.v1.ActivityTaskCompletedEventAttributes',
                result,
                #{}
            ),
            Index = {IdxKey, #{result => R}},
            % eqwalizer:ignore
            temporal_sdk_api_awaitable_index_table:upsert_index(IndexTable, Index);
        {value, {_, 'EVENT_TYPE_ACTIVITY_TASK_CANCELED', #{}, _}} ->
            Index = {IdxKey, #{result => 'ACTIVITY_TASK_CANCELED'}},
            % eqwalizer:ignore
            temporal_sdk_api_awaitable_index_table:upsert_index(IndexTable, Index);
        _ ->
            noevent
    end;
unblock_awaitable(UsupportedAwaitable, _HistoryEvents, _ApiCtx, _IndexTable) ->
    {error, #{
        reason => "Expected blocked awaitable, got unsupported awaitable.",
        unsupported_awaitable => UsupportedAwaitable
    }}.
