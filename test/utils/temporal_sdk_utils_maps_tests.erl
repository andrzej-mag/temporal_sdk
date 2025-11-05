-module(temporal_sdk_utils_maps_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-import(temporal_sdk_utils_maps, [
    pop/3,
    store/3,
    maybe_merge/4,
    map_if_ok/2,
    deep_merge_opts/2,
    deep_merge_opts/3
]).

pop_test() ->
    ?assertEqual({default, #{}}, pop(key, #{}, default)),
    ?assertEqual({default, #{k => v}}, pop(key, #{k => v}, default)),
    ?assertEqual({value, #{}}, pop(key, #{key => value}, default)),
    ?assertEqual({value, #{k => v}}, pop(key, #{key => value, k => v}, default)).

store_test() ->
    ?assertEqual(#{k => v}, store(k, #{}, v)),
    ?assertEqual(#{k => v, k1 => v1}, store(k, #{k1 => v1}, v)),
    ?assertEqual(#{k => v1}, store(k, #{k => v1}, v)).

maybe_merge_test() ->
    ?assertEqual(#{k => v}, maybe_merge(k, v, iv, #{})),
    ?assertEqual(#{k => v, k1 => v1}, maybe_merge(k, v, iv, #{k1 => v1})),
    ?assertEqual(#{}, maybe_merge(k, v, v, #{})),
    ?assertEqual(#{k1 => v1}, maybe_merge(k, v, v, #{k1 => v1})).

map_if_ok_test() ->
    ?assertEqual(
        {ok, #{k1 => {v1, mapped}}},
        map_if_ok(fun map_if_ok_test_fun_1/2, #{k1 => v1})
    ),
    ?assertEqual(
        {ok, #{k1 => {v1, mapped}, k2 => {v2, mapped}}},
        map_if_ok(fun map_if_ok_test_fun_1/2, #{k1 => v1, k2 => v2})
    ),
    ?assertEqual(
        {ok, #{k1 => {[v11, v12], mapped}}},
        map_if_ok(fun map_if_ok_test_fun_1/2, #{k1 => [v11, v12]})
    ),
    ?assertEqual(
        {ok, #{k1 => {v1, mapped}, k2 => {[v21, v22], mapped}}},
        map_if_ok(fun map_if_ok_test_fun_1/2, #{k1 => v1, k2 => [v21, v22]})
    ),
    ?assertEqual(
        {error, reason},
        map_if_ok(fun map_if_ok_test_fun_2/2, #{k1 => error})
    ),
    ?assertEqual(
        {error, reason},
        map_if_ok(fun map_if_ok_test_fun_2/2, #{k1 => v1, k2 => error})
    ),
    ?assertEqual(
        {error, reason},
        map_if_ok(fun map_if_ok_test_fun_2/2, #{k1 => [v11, v12], k2 => error})
    ),
    ?assertEqual(
        {error, reason},
        map_if_ok(fun map_if_ok_test_fun_2/2, #{k1 => error, k2 => [v21, v22]})
    ).

map_if_ok_test_fun_1(_Key, Value) -> {ok, {Value, mapped}}.

map_if_ok_test_fun_2(_Key, error) -> {error, reason};
map_if_ok_test_fun_2(_Key, Value) -> {ok, {Value, mapped}}.

deep_merge_opts_2_test() ->
    ?assertEqual(
        {ok, #{m1k1 => m1v1}},
        deep_merge_opts(#{m1k1 => m1v1}, #{})
    ),
    ?assertEqual(
        {ok, #{m1k1 => m1v1, m1k2 => m1v2}},
        deep_merge_opts(#{m1k1 => m1v1, m1k2 => m1v2}, #{})
    ),

    ?assertEqual(
        {ok, #{m1k1 => m2v1}},
        deep_merge_opts(#{m1k1 => m1v1}, #{m1k1 => m2v1})
    ),
    ?assertEqual(
        {ok, #{m1k1 => m2v1, m1k2 => m1v2}},
        deep_merge_opts(#{m1k1 => m1v1, m1k2 => m1v2}, #{m1k1 => m2v1})
    ),
    ?assertEqual(
        {ok, #{m1k1 => m1v1, m1k2 => m2v2}},
        deep_merge_opts(#{m1k1 => m1v1, m1k2 => m1v2}, #{m1k2 => m2v2})
    ),
    ?assertEqual(
        {ok, #{m1k1 => m2v1, m1k2 => m2v2}},
        deep_merge_opts(#{m1k1 => m1v1, m1k2 => m1v2}, #{m1k1 => m2v1, m1k2 => m2v2})
    ),
    ?assertEqual(
        {ok, #{m1k1 => m2v1, m1k2 => m2v2}},
        deep_merge_opts(#{m1k2 => m1v2, m1k1 => m1v1}, #{m1k1 => m2v1, m1k2 => m2v2})
    ),

    ?assertEqual(
        {ok, #{m1k1 => #{m1k11 => m1v11}}},
        deep_merge_opts(#{m1k1 => #{m1k11 => m1v11}}, #{})
    ),
    ?assertEqual(
        {ok, #{m1k1 => #{m1k11 => m1v11}, m1k2 => #{m1k21 => m1v21}}},
        deep_merge_opts(#{m1k1 => #{m1k11 => m1v11}, m1k2 => #{m1k21 => m1v21}}, #{})
    ),

    ?assertEqual(
        {ok, #{m1k1 => #{m1k11 => m2v11}}},
        deep_merge_opts(#{m1k1 => #{m1k11 => m1v11}}, #{m1k1 => #{m1k11 => m2v11}})
    ),
    ?assertEqual(
        {ok, #{m1k1 => #{m1k11 => m2v11}, m1k2 => m1v2}},
        deep_merge_opts(#{m1k1 => #{m1k11 => m1v11}, m1k2 => m1v2}, #{m1k1 => #{m1k11 => m2v11}})
    ),
    ?assertEqual(
        {ok, #{m1k1 => m1v1, m1k2 => #{m1k21 => m2v21}}},
        deep_merge_opts(#{m1k1 => m1v1, m1k2 => #{m1k21 => m1v21}}, #{m1k2 => #{m1k21 => m2v21}})
    ),
    ?assertEqual(
        {ok, #{m1k1 => #{m1k11 => m2v11}, m1k2 => #{m1k21 => m2v21}}},
        deep_merge_opts(#{m1k1 => #{m1k11 => m1v11}, m1k2 => #{m1k21 => m1v21}}, #{
            m1k1 => #{m1k11 => m2v11}, m1k2 => #{m1k21 => m2v21}
        })
    ),

    ?assertEqual(
        {ok, #{m1k1 => m2v1}},
        deep_merge_opts(#{m1k1 => #{m1k11 => m1v11}}, #{m1k1 => m2v1})
    ),
    ?assertEqual(
        {ok, #{m1k1 => #{m2k11 => m2v11}}},
        deep_merge_opts(#{m1k1 => m1v1}, #{m1k1 => #{m2k11 => m2v11}})
    ),

    ?assertMatch(
        {error, _},
        deep_merge_opts(#{m1k1 => m1v1}, #{m2k1 => m2v1})
    ),
    ?assertMatch(
        {error, _},
        deep_merge_opts(#{m1k1 => m1v1}, #{i1 => i1, i2 => i2})
    ).

deep_merge_opts_3_test() ->
    ?assertEqual(
        {ok, #{m1k1 => m1v1, rk1 => rv1}},
        deep_merge_opts(#{m1k1 => m1v1}, #{rk1 => rv1}, [rk1])
    ),
    ?assertEqual(
        {ok, #{m1k1 => m2v1, rk1 => rv1}},
        deep_merge_opts(#{m1k1 => m1v1}, #{m1k1 => m2v1, rk1 => rv1}, [rk1])
    ),
    ?assertEqual(
        {ok, #{m1k1 => m2v1, ak1 => av1}},
        deep_merge_opts(#{m1k1 => m1v1}, #{m1k1 => m2v1, ak1 => av1}, [ak1])
    ),
    ?assertEqual(
        {ok, #{m1k1 => m1v1, rk1 => #{rk11 => rv11}}},
        deep_merge_opts(#{m1k1 => m1v1}, #{rk1 => #{rk11 => rv11}}, [rk1])
    ),

    ?assertMatch(
        {error, _},
        deep_merge_opts(#{m1k1 => m1v1}, #{}, [rk1])
    ),
    ?assertMatch(
        {error, _},
        deep_merge_opts(#{m1k1 => m1v1}, #{i1 => i1, i2 => i2}, [rk1])
    ).

-endif.
