-module(temporal_sdk_grpc_compressor_gzip).
-behaviour(temporal_sdk_grpc_compressor).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    compress/4,
    decompress/4
]).

compress(_Cluster, Msg, _RequestInfo, _Opts) -> {zlib:gzip(Msg), 1, ~"gzip"}.

decompress(_Cluster, Msg, _RequestInfo, _Opts) -> zlib:gunzip(Msg).
