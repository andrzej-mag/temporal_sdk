-module(temporal_sdk_grpc_compressor).

% elp:ignore W0012 W0040
-moduledoc """
gRPC client compressor behaviour module.
""".

-export([
    compress/4,
    decompress/4
]).

-callback compress(
    Cluster :: temporal_sdk_grpc:cluster_name(),
    Msg :: binary(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    CompressOpts :: term()
) -> {nonempty_binary(), 0 | 1, nonempty_binary()}.

-callback decompress(
    Cluster :: temporal_sdk_grpc:cluster_name(),
    Msg :: nonempty_binary(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    DecompressOpts :: term()
) -> nonempty_binary().

-doc false.
-spec compress(
    Cluster :: temporal_sdk_grpc:cluster_name(),
    Msg :: binary(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    Opts :: temporal_sdk_grpc:opts()
) -> {nonempty_binary(), 0 | 1, nonempty_binary()}.
compress(
    Cluster, Msg, RequestInfo, #{compressor := {CompressorMod, CompressOpts, _DecompressOpts}}
) ->
    CompressorMod:compress(Cluster, Msg, RequestInfo, CompressOpts).

-doc false.
-spec decompress(
    Cluster :: temporal_sdk_grpc:cluster_name(),
    Msg :: nonempty_binary(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    Opts :: temporal_sdk_grpc:opts()
) -> nonempty_binary().
decompress(
    Cluster, Msg, RequestInfo, #{compressor := {CompressorMod, _CompressOpts, DecompressOpts}}
) ->
    CompressorMod:decompress(Cluster, Msg, RequestInfo, DecompressOpts).
