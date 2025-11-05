-module(temporal_sdk_utils_json).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    decode/1,
    encode/1
]).

-spec decode(Binary :: binary()) -> {ok, map()} | {error, Reason :: map()}.
decode(Binary) ->
    try json:decode(Binary) of
        R when is_map(R) -> {ok, R};
        _ -> {error, #{reason => "Invalid json binary.", binary => Binary}}
    catch
        error:Exception:_Stacktrace ->
            {error, #{
                reason => "Json decode error.",
                error => Exception,
                binary => Binary
            }}
    end.

-spec encode(Term :: json:encode_value()) -> {ok, iodata()} | {error, Reason :: map()}.
encode(Term) ->
    try json:encode(Term) of
        V -> {ok, V}
    catch
        error:Exception:_Stacktrace ->
            {error, #{
                reason => "Json encode error.",
                error => Exception,
                term => Term
            }}
    end.
