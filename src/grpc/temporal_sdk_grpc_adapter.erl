-module(temporal_sdk_grpc_adapter).

% elp:ignore W0012 W0040
-moduledoc """
gRPC client adapter behaviour module.
""".

-export([
    init_adapter/3,
    pools_status/1,
    request/6
]).

-callback init_adapter(Cluster :: temporal_sdk_grpc:cluster_name(), AdapterConfig :: term()) ->
    ok | {error, term()}.

-callback pools_status(Cluster :: temporal_sdk_grpc:cluster_name()) -> term().

-callback request(
    Cluster :: temporal_sdk_grpc:cluster_name(),
    Method :: iodata(),
    Path :: iodata(),
    Headers :: temporal_sdk_grpc:headers(),
    Body :: iodata(),
    Timeout :: timeout()
) ->
    {ok, Endpoint :: term(), Response :: binary(), RHeaders :: temporal_sdk_grpc:headers()}
    | {request_error, Endpoint :: term(), ErrorDetails :: term()}.

-doc false.
-spec init_adapter(
    AdapterModule :: module(),
    Cluster :: temporal_sdk_grpc:cluster_name(),
    AdapterConfig :: term()
) -> ok | {error, term()}.
init_adapter(AdapterModule, Cluster, AdapterConfig) ->
    AdapterModule:init_adapter(Cluster, AdapterConfig).

-doc false.
-spec pools_status(Cluster :: temporal_sdk_grpc:cluster_name()) -> term().
pools_status(Cluster) ->
    Adapter = temporal_sdk_grpc_opts:get_adapter(Cluster),
    Adapter:pools_status(Cluster).

-doc false.
-spec request(
    Cluster :: temporal_sdk_grpc:cluster_name(),
    Method :: iodata(),
    Path :: iodata(),
    Headers :: temporal_sdk_grpc:headers(),
    Body :: iodata(),
    Opts :: temporal_sdk_grpc:opts()
) ->
    {ok, Endpoint :: term(), Response :: binary(), RHeaders :: temporal_sdk_grpc:headers()}
    | {request_error, Endpoint :: term(), ErrorDetails :: term()}.
request(Cluster, Method, Path, Headers, Body, #{timeout := Timeout}) ->
    Adapter = temporal_sdk_grpc_opts:get_adapter(Cluster),
    Adapter:request(Cluster, Method, Path, Headers, Body, Timeout).
