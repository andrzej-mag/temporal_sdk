-module(temporal_sdk_utils_maps).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    pop/3,
    store/3,
    maybe_merge/4,
    map_if_ok/2,
    deep_merge_opts/2,
    deep_merge_opts/3
]).

-spec pop(Key :: term(), Map1 :: map(), Default :: term()) ->
    {ValueOrDefault :: term(), Map2 :: map()}.
pop(Key, Map, Default) ->
    case Map of
        #{Key := V} -> {V, maps:remove(Key, Map)};
        #{} -> {Default, Map}
    end.

-spec store(Key :: term(), Map :: map(), Value :: term()) -> map().
store(Key, Map, Value) when is_map(Map) ->
    case Map of
        #{Key := _} -> Map;
        #{} -> Map#{Key => Value}
    end.

-spec maybe_merge(Key :: term(), Value :: term(), IgnoredValue :: term(), Map :: map()) -> map().
maybe_merge(_Key, Value, Value, Map) -> Map;
maybe_merge(Key, Value, _IgnoredValue, Map) -> Map#{Key => Value}.

-spec map_if_ok(Fun :: fun((Key :: term(), Value1 :: term()) -> Value2 :: term()), Map :: map()) ->
    map() | {error, Reason :: term()} | term().
map_if_ok(Fun, Map) when is_function(Fun), is_map(Map) ->
    map_if_ok(maps:to_list(Map), Fun, []).

map_if_ok([{Key, Value} | T], Fun, Acc) ->
    case Fun(Key, Value) of
        {ok, V} -> map_if_ok(T, Fun, [{Key, V} | Acc]);
        Err -> Err
    end;
map_if_ok([], _Fun, Acc) ->
    {ok, maps:from_list(Acc)}.

-spec deep_merge_opts(Map1 :: map(), Map2 :: map()) ->
    {ok, MergedMap :: map()} | {error, {invalid_opts, map()}}.
deep_merge_opts(Map1, Map2) ->
    deep_merge_opts(Map1, Map2, []).

-spec deep_merge_opts(Map1 :: map(), Map2 :: map(), Required :: [term()]) ->
    {ok, MergedMap :: map()} | {error, {invalid_opts, map()}}.
deep_merge_opts(Map1, Map2, Required) ->
    do_deep_merge(
        lists:sort(proplists:from_map(Map1)),
        lists:sort(proplists:from_map(Map2)),
        lists:sort(Required),
        [],
        []
    ).

do_deep_merge([{K, V1} | TMap1], [{K, V2} | TMap2], Required, IAcc, Acc) when
    is_map(V1), is_map(V2)
->
    case deep_merge_opts(V1, V2) of
        {ok, V} -> do_deep_merge(TMap1, TMap2, Required, IAcc, [{K, V} | Acc]);
        Err -> Err
    end;
do_deep_merge([{K, _V1} | TMap1], [{K, V2} | TMap2], Required, IAcc, Acc) ->
    do_deep_merge(TMap1, TMap2, Required, IAcc, [{K, V2} | Acc]);
do_deep_merge(Map1, [{Required, V} | TMap2], [Required | TRequired], IAcc, Acc) ->
    do_deep_merge(Map1, TMap2, TRequired, IAcc, [{Required, V} | Acc]);
do_deep_merge([{K1, V1} | TMap1], [{K2, _V2} | TMap2] = Map2, Required, IAcc, Acc) ->
    case proplists:is_defined(K2, TMap1) of
        true ->
            do_deep_merge(TMap1, Map2, Required, IAcc, [{K1, V1} | Acc]);
        false ->
            do_deep_merge(TMap1, TMap2, Required, [K2 | IAcc], [{K1, V1} | Acc])
    end;
do_deep_merge([], [], [], [], Acc) ->
    {ok, proplists:to_map(Acc)};
do_deep_merge(Map1, [], [], [], Acc) ->
    {ok, proplists:to_map(Map1 ++ Acc)};
do_deep_merge(_, Map2, Required, IAcc, _Acc) ->
    {error,
        {invalid_opts, #{
            invalid_keys => IAcc ++ proplists:get_keys(Map2), missing_keys => Required
        }}}.
