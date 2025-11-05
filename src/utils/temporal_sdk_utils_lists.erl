-module(temporal_sdk_utils_lists).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    map_if_ok/2,
    keypop/3,
    take/2,
    nthreplace/3
]).

-spec map_if_ok(Fun :: fun((Value1 :: term()) -> Value2 :: term()), List :: list()) ->
    list() | {error, Reason :: term()} | term().
map_if_ok(Fun, List) when is_function(Fun), is_list(List) ->
    map_if_ok(List, Fun, []).

map_if_ok([L | TList], Fun, Acc) ->
    case Fun(L) of
        {ok, V} -> map_if_ok(TList, Fun, [V | Acc]);
        Err -> Err
    end;
map_if_ok([], _Fun, Acc) ->
    {ok, lists:reverse(Acc)}.

-spec keypop(Key :: term(), PropList :: [tuple()], Default :: term()) ->
    {ValueOrDefault :: term(), PropList1 :: [tuple()]}.
keypop(Key, PropList, Default) ->
    case lists:keytake(Key, 1, PropList) of
        false -> {Default, PropList};
        {value, {Key, V}, PropList1} -> {V, PropList1}
    end.

-spec take(Elem :: term(), List :: [T :: term()]) -> {ok, [T :: term()]} | error.
take(Elem, List) ->
    case lists:member(Elem, List) of
        true -> {ok, lists:delete(Elem, List)};
        false -> error
    end.

-spec nthreplace(N :: non_neg_integer(), List :: list(), NewElem :: term()) -> list().
nthreplace(N, List, NewElem) when N >= 1, N =< length(List) ->
    lists:sublist(List, N - 1) ++ [NewElem] ++ lists:nthtail(N, List).
