-module(temporal_sdk_grpc_converter_identity).
-behaviour(temporal_sdk_grpc_converter).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    convert/5
]).

convert(_MsgName, Msg, _Cluster, _RequestInfo, _ConverterOpts) -> {ok, Msg}.
