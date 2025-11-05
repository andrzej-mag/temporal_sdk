-module(temporal_sdk_utils).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    is_text_matching/2,
    uuid4/0,
    worker_version/0
]).

-define(WORKER_NAME, "temporal-sdk-erlang").
-define(INVALID_WORKER_VERSION, <<"temporal-sdk-erlang/unknown_version">>).

-spec is_text_matching(
    Text1 :: temporal_sdk_utils_unicode:data(), Text2 :: temporal_sdk_utils_unicode:data()
) ->
    boolean().
is_text_matching(Text1, Text2) when Text1 == Text2 -> true;
is_text_matching(Text1, Text2) ->
    maybe
        {ok, B1} ?= temporal_sdk_utils_unicode:characters_to_binary(Text1),
        {ok, B2} ?= temporal_sdk_utils_unicode:characters_to_binary(Text2),
        true ?= B1 == B2
    else
        false ->
            false;
        Err ->
            temporal_sdk_utils_logger:log_error(
                Err,
                ?MODULE,
                ?FUNCTION_NAME,
                "Non-unicode characters in Temporal event or command.",
                #{text1 => Text1, text2 => Text2}
            ),
            false
    end.

-spec uuid4() -> string().
uuid4() -> uuid:uuid_to_string(uuid:get_v4()).

-spec worker_version() -> binary().
worker_version() ->
    maybe
        {ok, Vsn} ?= application:get_key(temporal_sdk, vsn),
        Ver = temporal_sdk_utils_unicode:characters_to_binary1(
            temporal_sdk_utils_path:string_path([?WORKER_NAME, Vsn])
        ),
        true ?= is_binary(Ver),
        Ver
    else
        _ -> ?INVALID_WORKER_VERSION
    end.
