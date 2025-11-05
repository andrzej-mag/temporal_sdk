-module(temporal_sdk_utils_unicode_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-import(temporal_sdk_utils_unicode, [
    characters_to_binary/1,
    characters_to_list/1,
    characters_to_binary1/1,
    characters_to_list1/1
]).

-define(VALID_DATA, [16#10FFFF]).
-define(BINARY_UNICODE, <<244, 143, 191, 191>>).
-define(LIST_UNICODE, [1114111]).
-define(INVALID_DATA, [16#10FFFF + 1]).
-define(INVALID_DATA1, [16#10FFFF, 16#10FFFF + 1]).

characters_to_binary_test() ->
    ?assertEqual({ok, ?BINARY_UNICODE}, characters_to_binary(?VALID_DATA)),
    ?assertMatch({error, _}, characters_to_binary(?INVALID_DATA)),
    ?assertMatch({error, _}, characters_to_binary(?INVALID_DATA1)).

characters_to_list_test() ->
    ?assertEqual({ok, ?LIST_UNICODE}, characters_to_list(?VALID_DATA)),
    ?assertMatch({error, _}, characters_to_list(?INVALID_DATA)),
    ?assertMatch({error, _}, characters_to_list(?INVALID_DATA1)).

characters_to_binary1_test() ->
    ?assertEqual(?BINARY_UNICODE, characters_to_binary1(?VALID_DATA)),
    ?assertEqual(<<"___invalid_utf8_data">>, characters_to_binary1(?INVALID_DATA)),
    ?assertEqual(true, is_binary(characters_to_binary1(?INVALID_DATA1))).

characters_to_list1_test() ->
    ?assertEqual(?LIST_UNICODE, characters_to_list1(?VALID_DATA)),
    ?assertEqual("___invalid_utf8_data", characters_to_list1(?INVALID_DATA)),
    ?assertEqual(true, is_list(characters_to_list1(?INVALID_DATA1))).

-endif.
