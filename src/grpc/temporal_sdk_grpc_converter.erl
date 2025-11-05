-module(temporal_sdk_grpc_converter).

% elp:ignore W0012 W0040
-moduledoc """
gRPC client converter behaviour module.
""".

-export([
    run/4
]).

-callback convert(
    MsgName :: temporal_sdk_grpc:msg_name(),
    Msg :: temporal_sdk_grpc:msg(),
    Cluster :: temporal_sdk_grpc:cluster_name(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    ConverterOpts :: term()
) ->
    {ok, Msg :: temporal_sdk_grpc:msg()}
    | {ok, ConvertedMsg :: temporal_sdk_grpc:msg()}
    | {error, Reason :: term()}.

-doc false.
-spec run(
    Cluster :: temporal_sdk_grpc:cluster_name(),
    Msg :: temporal_sdk_grpc:msg(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    Opts :: temporal_sdk_grpc:opts()
) -> {ok, Msg :: temporal_sdk_grpc:msg()} | {error, Reason :: term()}.
run(
    Cluster,
    Msg,
    #{type := request, input := MsgName} = RequestInfo,
    #{converter := {ConverterMod, ConverterOpts}}
) ->
    ConverterMod:convert(MsgName, Msg, Cluster, RequestInfo, ConverterOpts);
run(
    Cluster,
    Msg,
    #{type := response, output := MsgName} = RequestInfo,
    #{converter := {ConverterMod, ConverterOpts}}
) ->
    ConverterMod:convert(MsgName, Msg, Cluster, RequestInfo, ConverterOpts).
