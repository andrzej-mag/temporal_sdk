-module(temporal_sdk_grpc_codec).

% elp:ignore W0012 W0040
-moduledoc """
gRPC client codec behaviour module.
""".

-export([
    encode_msg/4,
    decode_msg/5,
    from_json/4,
    to_json/4
]).

-callback encode_msg(
    Msg :: temporal_sdk_grpc:msg(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    Opts :: term()
) -> {ok, binary()} | {error, {codec_error, term()}}.

-callback decode_msg(
    Bin :: binary(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    HContentType :: binary() | atom(),
    Opts :: term()
) -> {ok, temporal_sdk_grpc:msg()} | {error, {codec_error, term()}}.

-callback from_json(
    Json :: map(),
    MsgName :: temporal_sdk_grpc:msg_name(),
    Opts :: term()
) -> {ok, temporal_sdk_grpc:msg()} | {error, {codec_error, term()}}.

-callback to_json(
    Msg :: temporal_sdk_grpc:msg(),
    MsgName :: temporal_sdk_grpc:msg_name(),
    Opts :: term()
) -> {ok, map()} | {error, {codec_error, term()}}.

-callback cast(TermToEncode :: term()) -> EncodedTerm :: term().

-optional_callbacks([
    cast/1
]).

-doc false.
-spec encode_msg(
    Codec :: module(),
    Msg :: temporal_sdk_grpc:msg(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    Opts :: term()
) -> {ok, binary()} | {error, {codec_error, term()}}.
encode_msg(Codec, Msg, RequestInfo, Opts) ->
    try Codec:encode_msg(Msg, RequestInfo, Opts) of
        {ok, R} when is_binary(R) -> {ok, R};
        {error, {codec_error, Reason}} -> {error, {codec_error, Reason}};
        {error, Reason} -> {error, {codec_error, Reason}};
        {error, Error, Reason} -> {error, {codec_error, {Error, Reason}}};
        Invalid -> {error, {codec_error, Invalid}}
    catch
        error:Reason:Stacktrace ->
            {error, {codec_error, {Reason, Stacktrace}}}
    end.

-doc false.
-spec decode_msg(
    Codec :: module(),
    Msg :: binary(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    HContentType :: binary() | atom(),
    Opts :: term()
) -> {ok, temporal_sdk_grpc:msg()} | {error, {codec_error, term()}}.
decode_msg(Codec, Msg, RequestInfo, HContentType, Opts) ->
    try Codec:decode_msg(Msg, RequestInfo, HContentType, Opts) of
        {ok, R} when is_map(R) -> {ok, R};
        {error, {codec_error, Reason}} -> {error, {codec_error, Reason}};
        {error, Reason} -> {error, {codec_error, Reason}};
        {error, Error, Reason} -> {error, {codec_error, {Error, Reason}}};
        Invalid -> {error, {codec_error, Invalid}}
    catch
        error:Reason:Stacktrace ->
            {error, {codec_error, {Reason, Stacktrace}}}
    end.

-doc false.
-spec from_json(
    Codec :: module(),
    Json :: map(),
    MsgName :: temporal_sdk_grpc:msg_name(),
    Opts :: term()
) ->
    {ok, temporal_sdk_grpc:msg()} | {error, Reason :: term()}.
from_json(Codec, Json, MsgName, Opts) ->
    try Codec:from_json(Json, MsgName, Opts) of
        {ok, R} when is_map(R) -> {ok, R};
        {error, {codec_error, Reason}} -> {error, {codec_error, Reason}};
        {error, Reason} -> {error, {codec_error, Reason}};
        {error, Error, Reason} -> {error, {codec_error, {Error, Reason}}};
        Invalid -> {error, {codec_error, Invalid}}
    catch
        error:Reason:Stacktrace ->
            {error, {codec_error, {Reason, Stacktrace}}}
    end.

-doc false.
-spec to_json(
    Codec :: module(),
    Msg :: temporal_sdk_grpc:msg(),
    MsgName :: temporal_sdk_grpc:msg_name(),
    Opts :: term()
) ->
    {ok, map()} | {error, Reason :: term()}.
to_json(Codec, Msg, MsgName, Opts) ->
    try Codec:to_json(Msg, MsgName, Opts) of
        {ok, R} when is_map(R) -> {ok, R};
        {error, {codec_error, Reason}} -> {error, {codec_error, Reason}};
        {error, Reason} -> {error, {codec_error, Reason}};
        {error, Error, Reason} -> {error, {codec_error, {Error, Reason}}};
        Invalid -> {error, {codec_error, Invalid}}
    catch
        error:Reason:Stacktrace ->
            {error, {codec_error, {Reason, Stacktrace}}}
    end.
