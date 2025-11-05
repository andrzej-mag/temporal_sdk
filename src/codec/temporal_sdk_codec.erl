-module(temporal_sdk_codec).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    encode_msg/4,
    decode_msg/5,
    from_json/4,
    to_json/4
]).

-define(HEADER_CONTENT_TYPE, ~"application/grpc+proto").

encode_msg(Msg, MsgName, Opts, Mod) ->
    try Mod:encode_msg(Msg, MsgName, Opts) of
        MsgBin when is_binary(MsgBin) -> {ok, MsgBin}
    catch
        _Class:Exception:Stacktrace ->
            {error, {codec_error, #{codec => Mod, error => Exception, stacktrace => Stacktrace}}}
    end.

decode_msg(Msg, MsgName, ?HEADER_CONTENT_TYPE, Opts, Mod) ->
    try Mod:decode_msg(Msg, MsgName, Opts) of
        MsgDecoded when is_map(MsgDecoded) -> {ok, MsgDecoded}
    catch
        _Class:Exception:Stacktrace ->
            {error, {codec_error, #{codec => Mod, error => Exception, stacktrace => Stacktrace}}}
    end;
decode_msg(_Msg, _MsgName, Header, _Opts, _Mod) ->
    {error, {codec_error, #{error => unsupported_content_type, headers => Header}}}.

from_json(Json, MsgName, Opts, Mod) ->
    try Mod:from_json(Json, MsgName, Opts) of
        Msg when is_map(Msg) -> {ok, Msg}
    catch
        _Class:Exception:Stacktrace ->
            {error, {codec_error, #{codec => Mod, error => Exception, stacktrace => Stacktrace}}}
    end.

to_json(Msg, MsgName, Opts, Mod) ->
    try Mod:to_json(Msg, MsgName, Opts) of
        Json when is_map(Json) -> {ok, Json}
    catch
        _Class:Exception:Stacktrace ->
            {error, {codec_error, #{codec => Mod, error => Exception, stacktrace => Stacktrace}}}
    end.
