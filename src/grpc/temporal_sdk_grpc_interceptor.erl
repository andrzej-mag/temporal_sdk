-module(temporal_sdk_grpc_interceptor).

% elp:ignore W0012 W0040
-moduledoc """
gRPC client interceptor behaviour module.
""".

-export([
    run/4
]).

-callback handle_request(
    Cluster :: temporal_sdk_grpc:cluster_name(),
    Msg :: temporal_sdk_grpc:msg(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    HandleRequestOpts :: term()
) -> {ok, Msg :: temporal_sdk_grpc:msg()} | {error, Reason :: term()}.

-callback handle_response(
    Cluster :: temporal_sdk_grpc:cluster_name(),
    Msg :: temporal_sdk_grpc:msg(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    HandleResponseOpts :: term()
) -> {ok, Msg :: temporal_sdk_grpc:msg()} | {error, Reason :: term()}.

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
    #{type := request} = RequestInfo,
    #{interceptor := {InterceptorMod, HandleRequestOpts, _HandleResponseOpts}}
) ->
    InterceptorMod:handle_request(Cluster, Msg, RequestInfo, HandleRequestOpts);
run(
    Cluster,
    Msg,
    #{type := response} = RequestInfo,
    #{interceptor := {InterceptorMod, _HandleRequestOpts, HandleResponseOpts}}
) ->
    InterceptorMod:handle_response(Cluster, Msg, RequestInfo, HandleResponseOpts).
