-module(temporal_sdk_utils_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-import(temporal_sdk_utils, [
    is_text_matching/2,
    uuid4/0,
    worker_version/0
]).

is_text_matching_test() ->
    ?assertEqual(true, is_text_matching("test", "test")),
    ?assertEqual(true, is_text_matching(<<"test">>, <<"test">>)),
    ?assertEqual(true, is_text_matching("test", <<"test">>)),
    ?assertEqual(true, is_text_matching(<<"test">>, "test")),

    ?assertEqual(false, is_text_matching("test1", "test")),
    ?assertEqual(false, is_text_matching(<<"test1">>, <<"test">>)),
    ?assertEqual(false, is_text_matching("test1", <<"test">>)),
    ?assertEqual(false, is_text_matching(<<"test1">>, "test")).

uuid4_test() ->
    ?assert(io_lib:char_list(uuid4())).

worker_version_test() ->
    ?assert(is_binary(worker_version())).

-endif.
