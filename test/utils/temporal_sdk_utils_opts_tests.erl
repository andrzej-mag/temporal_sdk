-module(temporal_sdk_utils_opts_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-import(temporal_sdk_utils_opts, [
    build/2,
    build/3
]).

build_test() ->
    ?assertEqual(
        {ok, #{}},
        build(
            [],
            []
        )
    ),
    ?assertEqual(
        {error, {invalid_opts, [{invalid_k, invalid_v}]}},
        build(
            [],
            [{invalid_k, invalid_v}]
        )
    ),
    ?assertEqual(
        {error, {invalid_opts, [{invalid_k, true}]}},
        build(
            [],
            [invalid_k]
        )
    ),

    ?assertEqual(
        {ok, #{}},
        build(
            [{ka, any, '$_optional'}],
            []
        )
    ),
    ?assertEqual(
        {ok, #{}},
        build(
            [{ki, pos_integer, '$_optional'}],
            []
        )
    ),
    ?assertEqual(
        {ok, #{}},
        build(
            [{km, map, '$_optional'}],
            []
        )
    ),
    ?assertEqual(
        {ok, #{}},
        build(
            [{ka, any, '$_optional'}, {ki, pos_integer, '$_optional'}, {km, map, '$_optional'}],
            []
        )
    ),

    ?assertEqual(
        {ok, #{ka => va}},
        build(
            [{ka, any, '$_optional'}],
            [{ka, va}]
        )
    ),
    ?assertEqual(
        {ok, #{ki => 123}},
        build(
            [{ki, pos_integer, '$_optional'}],
            [{ki, 123}]
        )
    ),
    ?assertEqual(
        {ok, #{km => #{a => b}}},
        build(
            [{km, map, '$_optional'}],
            [{km, #{a => b}}]
        )
    ),
    ?assertEqual(
        {ok, #{ka => va, ki => 123, km => #{a => b}}},
        build(
            [{ka, any, '$_optional'}, {ki, pos_integer, '$_optional'}, {km, map, '$_optional'}],
            [{ka, va}, {ki, 123}, {km, #{a => b}}]
        )
    ),

    ?assertEqual(
        {error, {invalid_opts, #{missing_opts => ka}}},
        build(
            [{ka, any, '$_required'}],
            []
        )
    ),
    ?assertEqual(
        {error, {invalid_opts, #{missing_opts => ki}}},
        build(
            [{ki, pos_integer, '$_required'}],
            []
        )
    ),
    ?assertEqual(
        {error, {invalid_opts, #{missing_opts => km}}},
        build(
            [{km, map, '$_required'}],
            []
        )
    ),
    ?assertMatch(
        {error, {invalid_opts, #{missing_opts := _}}},
        build(
            [{ka, any, '$_required'}, {ki, pos_integer, '$_required'}, {km, map, '$_required'}],
            []
        )
    ),

    ?assertEqual(
        {ok, #{ka => va}},
        build(
            [{ka, any, '$_required'}],
            [{ka, va}]
        )
    ),
    ?assertEqual(
        {ok, #{ki => 123}},
        build(
            [{ki, pos_integer, '$_required'}],
            [{ki, 123}]
        )
    ),
    ?assertEqual(
        {ok, #{km => #{a => b}}},
        build(
            [{km, map, '$_required'}],
            [{km, #{a => b}}]
        )
    ),
    ?assertEqual(
        {ok, #{ka => va, ki => 123, km => #{a => b}}},
        build(
            [{ka, any, '$_required'}, {ki, pos_integer, '$_required'}, {km, map, '$_required'}],
            [{ka, va}, {ki, 123}, {km, #{a => b}}]
        )
    ),

    ?assertEqual(
        {error, {invalid_opts, #{invalid_value => invalid, expected_value_type => pos_integer}}},
        build(
            [{ki, pos_integer, '$_optional'}],
            [{ki, invalid}]
        )
    ),
    ?assertEqual(
        {error, {invalid_opts, #{invalid_value => invalid, expected_value_type => map}}},
        build(
            [{km, map, '$_optional'}],
            [{km, invalid}]
        )
    ),
    ?assertMatch(
        {error, {invalid_opts, #{invalid_value := invalid, expected_value_type := _}}},
        build(
            [{ka, any, '$_optional'}, {ki, pos_integer, '$_optional'}, {km, map, '$_optional'}],
            [{ka, va}, {ki, invalid}, {km, invalid}]
        )
    ),

    ?assertEqual(
        {error, {invalid_opts, #{invalid_value => invalid, expected_value_type => pos_integer}}},
        build(
            [{ki, pos_integer, '$_required'}],
            [{ki, invalid}]
        )
    ),
    ?assertEqual(
        {error, {invalid_opts, #{invalid_value => invalid, expected_value_type => map}}},
        build(
            [{km, map, '$_required'}],
            [{km, invalid}]
        )
    ),
    ?assertMatch(
        {error, {invalid_opts, #{invalid_value := invalid, expected_value_type := _}}},
        build(
            [{ka, any, '$_required'}, {ki, pos_integer, '$_required'}, {km, map, '$_required'}],
            [{ka, va}, {ki, invalid}, {km, invalid}]
        )
    ),

    ?assertEqual(
        {ok, #{ka => va}},
        build(
            [{ka, any, va}],
            []
        )
    ),
    ?assertEqual(
        {ok, #{ki => 123}},
        build(
            [{ki, pos_integer, 123}],
            []
        )
    ),
    ?assertEqual(
        {ok, #{km => #{a => b}}},
        build(
            [{km, map, #{a => b}}],
            []
        )
    ),
    ?assertEqual(
        {ok, #{ka => va, ki => 123, km => #{a => b}}},
        build(
            [{ka, any, va}, {ki, pos_integer, 123}, {km, map, #{a => b}}],
            []
        )
    ),

    ?assertEqual(
        {ok, #{ka => va}},
        build(
            [{ka, any, vaa}],
            [{ka, va}]
        )
    ),
    ?assertEqual(
        {ok, #{ki => 123}},
        build(
            [{ki, pos_integer, 123_456}],
            [{ki, 123}]
        )
    ),
    ?assertEqual(
        {ok, #{km => #{a => b}}},
        build(
            [{km, map, #{aa => bb}}],
            [{km, #{a => b}}]
        )
    ),
    ?assertEqual(
        {ok, #{ka => va, ki => 123, km => #{a => b}}},
        build(
            [{ka, any, vaa}, {ki, pos_integer, 123_456}, {km, map, #{aa => bb}}],
            [{ka, va}, {ki, 123}, {km, #{a => b}}]
        )
    ),

    ?assertEqual(
        {error, {invalid_opts, #{invalid_value => invalid, expected_value_type => pos_integer}}},
        build(
            [{ki, pos_integer, invalid}],
            []
        )
    ),
    ?assertEqual(
        {error, {invalid_opts, #{invalid_value => invalid, expected_value_type => map}}},
        build(
            [{km, map, invalid}],
            []
        )
    ),
    ?assertMatch(
        {error, {invalid_opts, #{invalid_value := invalid, expected_value_type := _}}},
        build(
            [{ka, any, va}, {ki, pos_integer, invalid}, {km, map, invalid}],
            []
        )
    ),

    ?assertEqual(
        {error, {invalid_opts, #{invalid_value => invalid, expected_value_type => pos_integer}}},
        build(
            [{ki, pos_integer, invalid}],
            [{ki, invalid}]
        )
    ),
    ?assertEqual(
        {error, {invalid_opts, #{invalid_value => invalid, expected_value_type => map}}},
        build(
            [{km, map, invalid}],
            [{km, invalid}]
        )
    ),
    ?assertMatch(
        {error, {invalid_opts, #{invalid_value := invalid, expected_value_type := _}}},
        build(
            [{ka, any, va}, {ki, pos_integer, invalid}, {km, map, invalid}],
            [{ka, va}, {ki, invalid}, {km, invalid}]
        )
    ),

    ?assertEqual(
        {error, {invalid_opts, #{invalid_value => invalid, expected_value_type => pos_integer}}},
        build(
            [{ki, pos_integer, 123}],
            [{ki, invalid}]
        )
    ),
    ?assertEqual(
        {error, {invalid_opts, #{invalid_value => invalid, expected_value_type => map}}},
        build(
            [{km, map, #{a => b}}],
            [{km, invalid}]
        )
    ),
    ?assertMatch(
        {error, {invalid_opts, #{invalid_value := invalid, expected_value_type := _}}},
        build(
            [{ka, any, va}, {ki, 123, invalid}, {km, map, #{a => b}}],
            [{ka, va}, {ki, invalid}, {km, invalid}]
        )
    ),

    ?assertEqual(
        {ok, #{}},
        build(
            [{ka, duration, '$_optional'}],
            []
        )
    ),
    ?assertEqual(
        {error, {invalid_opts, #{missing_opts => ka}}},
        build(
            [{ka, duration, '$_required'}],
            []
        )
    ),
    ?assertEqual(
        {ok, #{ka => #{seconds => 0, nanos => 123000000}}},
        build(
            [{ka, duration, 123}],
            []
        )
    ),
    ?assertEqual(
        {ok, #{ka => #{seconds => 0, nanos => 123000000}}},
        build(
            [{ka, duration, 123_456}],
            [{ka, 123}]
        )
    ),
    ?assertEqual(
        {ok, #{ka => #{seconds => 90, nanos => 0}}},
        build(
            [{ka, duration, '$_required'}],
            [{ka, {1.5, minute}}]
        )
    ),

    ?assertEqual(
        {ok, #{ki => true}},
        build(
            [{ki, [pos_integer, boolean], 123_456}],
            [{ki, true}]
        )
    ),
    ?assertEqual(
        {ok, #{km => #{a => b}}},
        build(
            [{km, [map, boolean], #{aa => bb}}],
            [{km, #{a => b}}]
        )
    ),
    ?assertEqual(
        {ok, #{ka => va, ki => #{c => d}, km => #{a => b}}},
        build(
            [{ka, any, vaa}, {ki, [integer, map], 123_456}, {km, map, #{aa => bb}}],
            [{ka, va}, {ki, #{c => d}}, {km, #{a => b}}]
        )
    ),

    ?assertEqual(
        {error,
            {invalid_opts, #{
                invalid_value => invalid, expected_value_type => [pos_integer, boolean]
            }}},
        build(
            [{ki, [pos_integer, boolean], 123_456}],
            [{ki, invalid}]
        )
    ),
    ?assertEqual(
        {error, {invalid_opts, #{invalid_value => invalid, expected_value_type => [map, boolean]}}},
        build(
            [{km, [map, boolean], #{aa => bb}}],
            [{km, invalid}]
        )
    ),
    ?assertEqual(
        {error, {invalid_opts, #{invalid_value => invalid, expected_value_type => [integer, map]}}},
        build(
            [{ka, any, vaa}, {ki, [integer, map], 123_456}, {km, map, #{aa => bb}}],
            [{ka, va}, {ki, invalid}, {km, #{a => b}}]
        )
    ),

    ?assertEqual(
        {ok, #{km => #{a => b, aa => bb}}},
        build(
            [{km, map, #{aa => bb}, merge}],
            [{km, #{a => b}}]
        )
    ),
    ?assertEqual(
        {ok, #{km => #{a => b, aa => bb}}},
        build(
            [{km, [undefined, map], #{aa => bb}, merge}],
            [{km, #{a => b}}]
        )
    ),

    ?assertEqual(
        {ok, #{km => #{a => b}, k1 => #{k2 => 123}}},
        build(
            [{k1, nested, [{k2, integer, 123}]}, {km, map, #{}}],
            [{km, #{a => b}}]
        )
    ),

    ExpectedNested = #{
        limits => #{worker => #{activity_regular => {5, 10}}}, namespace => "default"
    },
    ?assertEqual(
        {ok, ExpectedNested},
        build(
            defaults(worker_opts),
            #{limits => #{worker => #{activity_regular => {5, 10}}}}
        )
    ),
    ?assertEqual(
        {ok, ExpectedNested},
        build(
            defaults(worker_opts),
            [{limits, #{worker => #{activity_regular => {5, 10}}}}]
        )
    ),
    ?assertEqual(
        {ok, ExpectedNested},
        build(
            defaults(worker_opts),
            [{limits, [{worker, #{activity_regular => {5, 10}}}]}]
        )
    ),
    ?assertEqual(
        {ok, ExpectedNested},
        build(
            defaults(worker_opts),
            [{limits, #{worker => [{activity_regular, {5, 10}}]}}]
        )
    ),
    ?assertEqual(
        {ok, ExpectedNested},
        build(
            defaults(worker_opts),
            [{limits, [{worker, [{activity_regular, {5, 10}}]}]}]
        )
    ).

defaults(worker_opts) ->
    [{namespace, unicode, "default"}, {limits, nested, defaults(limits)}];
defaults(limits) ->
    [{worker, nested, defaults(worker_limits)}];
defaults(worker_limits) ->
    [{activity_regular, tuple, '$_optional'}].

-endif.
