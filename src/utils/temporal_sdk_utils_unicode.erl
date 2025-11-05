-module(temporal_sdk_utils_unicode).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    characters_to_binary/1,
    characters_to_list/1,
    characters_to_binary1/1,
    characters_to_list1/1
]).

-type data() :: unicode:chardata() | unicode:latin1_chardata() | unicode:external_chardata().
-export_type([data/0]).

-spec characters_to_binary(Data :: data()) -> {ok, binary()} | {error, term()}.
characters_to_binary(Data) ->
    case unicode:characters_to_binary(Data) of
        {error, Binary, Rest} ->
            {error, {"Invalid utf8 unicode.", #{data => Data, valid => Binary, rest => Rest}}};
        {incomplete, Binary, Rest} ->
            {error, {"Incomplete utf8 unicode.", #{data => Data, valid => Binary, rest => Rest}}};
        Binary ->
            {ok, Binary}
    end.

-spec characters_to_list(Data :: data()) -> {ok, string()} | {error, term()}.
characters_to_list(Data) ->
    case unicode:characters_to_list(Data) of
        {error, String, Rest} ->
            {error, {"Invalid utf8 unicode.", #{data => Data, valid => String, rest => Rest}}};
        {incomplete, String, Rest} ->
            {error, {"Incomplete utf8 unicode.", #{data => Data, valid => String, rest => Rest}}};
        String ->
            {ok, String}
    end.

-spec characters_to_binary1(Data :: data()) -> binary().
characters_to_binary1(Data) ->
    case unicode:characters_to_binary(Data) of
        {error, Binary, _Rest} -> <<Binary/binary, <<"___invalid_utf8_data">>/binary>>;
        {incomplete, Binary, _Rest} -> <<Binary/binary, <<"___incomplete_utf8_data">>/binary>>;
        Binary -> Binary
    end.

-spec characters_to_list1(Data :: data()) -> string().
characters_to_list1(Data) ->
    case unicode:characters_to_list(Data) of
        {error, String, _Rest} -> String ++ "___invalid_utf8_data";
        {incomplete, String, _Rest} -> String ++ "___incomplete_utf8_data";
        String -> String
    end.
