-module(temporal_sdk_utils_lists_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-import(temporal_sdk_utils_lists, [
    map_if_ok/2,
    keypop/3,
    take/2
]).

map_if_ok_test() ->
    ?assertEqual(
        {ok, [{v1, mapped}]},
        map_if_ok(fun map_if_ok_test_fun_1/1, [v1])
    ),
    ?assertEqual(
        {ok, [{v1, mapped}, {v2, mapped}]},
        map_if_ok(fun map_if_ok_test_fun_1/1, [v1, v2])
    ),
    ?assertEqual(
        {ok, [{v1, mapped}, {[v2], mapped}]},
        map_if_ok(fun map_if_ok_test_fun_1/1, [v1, [v2]])
    ),
    ?assertEqual(
        {ok, [{v1, mapped}, {#{k2 => v2}, mapped}]},
        map_if_ok(fun map_if_ok_test_fun_1/1, [v1, #{k2 => v2}])
    ),
    ?assertEqual(
        {error, reason},
        map_if_ok(fun map_if_ok_test_fun_2/1, [error])
    ),
    ?assertEqual(
        {error, reason},
        map_if_ok(fun map_if_ok_test_fun_2/1, [v1, error])
    ),
    ?assertEqual(
        {error, reason},
        map_if_ok(fun map_if_ok_test_fun_2/1, [error, v2])
    ),
    ?assertEqual(
        {error, reason},
        map_if_ok(fun map_if_ok_test_fun_2/1, [v1, v2, error])
    ).

map_if_ok_test_fun_1(Value) -> {ok, {Value, mapped}}.

map_if_ok_test_fun_2(error) -> {error, reason};
map_if_ok_test_fun_2(Value) -> {ok, {Value, mapped}}.

keypop_test() ->
    ?assertEqual({default, []}, keypop(key, [], default)),
    ?assertEqual({default, [{k, v}]}, keypop(key, [{k, v}], default)),
    ?assertEqual({value, []}, keypop(key, [{key, value}], default)),
    ?assertEqual({value, [{k, v}]}, keypop(key, [{key, value}, {k, v}], default)).

take_test() ->
    ?assertEqual(error, take(key, [])),
    ?assertEqual(error, take(key, [a, b])),
    ?assertEqual({ok, [b]}, take(a, [a, b])).

-endif.
