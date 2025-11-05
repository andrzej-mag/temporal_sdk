-module(temporal_sdk_grpc_interceptor_identity).
-behaviour(temporal_sdk_grpc_interceptor).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    handle_request/4,
    handle_response/4
]).

handle_request(_Cluster, Msg, _RequestInfo, _Opts) -> {ok, Msg}.

handle_response(_Cluster, Msg, _RequestInfo, _Opts) -> {ok, Msg}.
