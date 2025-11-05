-module(temporal_sdk_utils_time_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-import(temporal_sdk_utils_time, [
    convert_to_msec/2,
    msec_to_protobuf/1,
    nanos_to_protobuf/1,
    protobuf_to_msec/1
]).

-define(TEST_TIME, 123_456_789).

convert_to_msec_test() ->
    ?assertEqual(?TEST_TIME, convert_to_msec(?TEST_TIME, millisecond)),
    ?assertEqual(1000 * ?TEST_TIME, convert_to_msec(?TEST_TIME, second)),
    ?assertEqual(60 * 1000 * ?TEST_TIME, convert_to_msec(?TEST_TIME, minute)),
    ?assertEqual(60 * 60 * 1000 * ?TEST_TIME, convert_to_msec(?TEST_TIME, hour)),
    ?assertEqual(24 * 60 * 60 * 1000 * ?TEST_TIME, convert_to_msec(?TEST_TIME, day)),

    ?assertEqual(round(1000 * ?TEST_TIME / 2), convert_to_msec(?TEST_TIME / 2, second)),
    ?assertEqual(round(60 * 1000 * ?TEST_TIME / 2), convert_to_msec(?TEST_TIME / 2, minute)),
    ?assertEqual(round(60 * 60 * 1000 * ?TEST_TIME / 2), convert_to_msec(?TEST_TIME / 2, hour)),
    ?assertEqual(round(24 * 60 * 60 * 1000 * ?TEST_TIME / 2), convert_to_msec(?TEST_TIME / 2, day)).

msec_to_protobuf_test() ->
    ?assertEqual(#{seconds => 0, nanos => 0}, msec_to_protobuf(0)),
    ?assertEqual(#{seconds => 0, nanos => 1_000_000}, msec_to_protobuf(1)),
    ?assertEqual(#{seconds => 0, nanos => 10_000_000}, msec_to_protobuf(10)),
    ?assertEqual(#{seconds => 0, nanos => 100_000_000}, msec_to_protobuf(100)),
    ?assertEqual(#{seconds => 1, nanos => 0}, msec_to_protobuf(1_000)),
    ?assertEqual(#{seconds => 10, nanos => 0}, msec_to_protobuf(10_000)),
    ?assertEqual(#{seconds => 100, nanos => 0}, msec_to_protobuf(100_000)),
    ?assertEqual(#{seconds => 100, nanos => 1_000_000}, msec_to_protobuf(100_001)).

nanos_to_protobuf_test() ->
    ?assertEqual(#{seconds => 0, nanos => 0}, nanos_to_protobuf(0)),
    ?assertEqual(#{seconds => 0, nanos => 1}, nanos_to_protobuf(1)),
    ?assertEqual(#{seconds => 0, nanos => 1_000}, nanos_to_protobuf(1_000)),
    ?assertEqual(#{seconds => 1, nanos => 0}, nanos_to_protobuf(1_000_000_000)),
    ?assertEqual(#{seconds => 1, nanos => 1}, nanos_to_protobuf(1_000_000_001)).

protobuf_to_msec_test() ->
    ?assertEqual(0, protobuf_to_msec(#{seconds => 0})),
    ?assertEqual(0, protobuf_to_msec(#{nanos => 0})),
    ?assertEqual(0, protobuf_to_msec(#{seconds => 0, nanos => 0})),
    ?assertEqual(0, protobuf_to_msec(#{nanos => 1})),
    ?assertEqual(0, protobuf_to_msec(#{seconds => 0, nanos => 1})),
    ?assertEqual(0, protobuf_to_msec(#{nanos => 1_000})),
    ?assertEqual(0, protobuf_to_msec(#{seconds => 0, nanos => 1_000})),
    ?assertEqual(1, protobuf_to_msec(#{nanos => 500_000})),
    ?assertEqual(1, protobuf_to_msec(#{seconds => 0, nanos => 500_000})),
    ?assertEqual(1, protobuf_to_msec(#{nanos => 800_000})),
    ?assertEqual(1, protobuf_to_msec(#{seconds => 0, nanos => 900_000})),
    ?assertEqual(1, protobuf_to_msec(#{nanos => 1_000_000})),
    ?assertEqual(1, protobuf_to_msec(#{seconds => 0, nanos => 1_000_000})),
    ?assertEqual(10, protobuf_to_msec(#{nanos => 10_000_000})),
    ?assertEqual(10, protobuf_to_msec(#{seconds => 0, nanos => 10_000_000})),
    ?assertEqual(1_000, protobuf_to_msec(#{seconds => 1})),
    ?assertEqual(1_001, protobuf_to_msec(#{seconds => 1, nanos => 1_000_000})),
    ?assertEqual(10_000, protobuf_to_msec(#{seconds => 10})),
    ?assertEqual(10_001, protobuf_to_msec(#{seconds => 10, nanos => 1_000_000})).

-endif.
