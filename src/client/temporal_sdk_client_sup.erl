-module(temporal_sdk_client_sup).
-behaviour(supervisor).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    start_link/2
]).
-export([
    init/1
]).

-spec start_link(
    Cluster :: temporal_sdk_cluster:cluster_name(), ClientOpts :: temporal_sdk_client:opts()
) -> supervisor:startlink_ret().
start_link(Cluster, ClientOpts) ->
    supervisor:start_link(
        {local, temporal_sdk_utils_path:atom_path([?MODULE, Cluster])}, ?MODULE, [
            Cluster, ClientOpts
        ]
    ).

init([Cluster, ClientOpts]) ->
    maybe
        #{
            adapter := Adapter,
            pool_size := PoolSize,
            grpc_opts := GrpcOpts,
            grpc_opts_longpoll := GrpcOptsLongpoll
        } ?= ClientOpts,
        ok ?= temporal_sdk_grpc_opts:check_opts(GrpcOpts),
        ok ?= temporal_sdk_grpc_opts:check_opts(GrpcOptsLongpoll),
        ok ?= temporal_sdk_grpc:start_grpc(Cluster, Adapter),
        {ok, {#{strategy => one_for_one}, child_spec(Cluster, PoolSize)}}
    else
        Err ->
            temporal_sdk_utils_logger:log_error(
                "Invalid Temporal SDK configuration.",
                ?MODULE,
                ?FUNCTION_NAME,
                "Error starting client supervisor. "
                "Check client configuration. "
                "SDK client not started.",
                Err
            ),
            {ok, {#{strategy => one_for_one}, []}}
    end.

child_spec(Cluster, Size) ->
    [
        #{
            id => {temporal_sdk_client, Cluster, I},
            start => {temporal_sdk_client, start_link, [Cluster, I]}
        }
     || I <- lists:seq(1, Size)
    ].
