-module(temporal_sdk_grpc_adapter_gun_pool).
-behaviour(temporal_sdk_grpc_adapter).

% elp:ignore W0012 W0040
-moduledoc """
gRPC client adapter using `m:gun_pool`.
""".

-export([
    init_adapter/2,
    pools_status/1,
    request/6
]).

-type config() :: [
    {endpoints, [temporal_sdk_grpc_adapter_gun:endpoint()]}
    | {gun_opts, gun:opts()}
    | {pool_size, pos_integer()}
].
-export_type([config/0]).

-define(DEFAULT_POOL_SIZE, 100).

-doc false.
-spec init_adapter(Cluster :: temporal_sdk_grpc:cluster_name(), Config :: config()) ->
    ok | {error, term()}.
init_adapter(Cluster, Config) ->
    PoolSize = proplists:get_value(pool_size, Config, ?DEFAULT_POOL_SIZE),
    case temporal_sdk_grpc_adapter_gun_common:init_endpoints(Config) of
        {ok, Endpoints} ->
            Pools = lists:flatten([start_pool(Cluster, E, PoolSize) || E <- Endpoints]),
            temporal_sdk_grpc_adapter_gun_common:set_config(?MODULE, Cluster, Pools);
        Err ->
            Err
    end.

-doc false.
-spec pools_status(Cluster :: temporal_sdk_grpc:cluster_name()) ->
    #{all := [binary()], operational := [binary()]} | {error, invalid_cluster}.
pools_status(Cluster) ->
    case temporal_sdk_cluster:is_alive(Cluster) of
        true ->
            Pools = temporal_sdk_grpc_adapter_gun_common:get_config(?MODULE, Cluster),
            % eqwalizer:ignore
            OperationalPools = fetch_operational_gun_pools(Cluster, Pools),
            % eqwalizer:ignore
            #{all => Pools, operational => OperationalPools};
        Err ->
            Err
    end.

-doc false.
request(Cluster, Method, Path, Headers, Body, Timeout) ->
    Pool = pick_pool(Cluster),
    maybe
        {async, GunRef} ?=
            gun_pool:request(
                Method,
                Path,
                add_host_header(Headers, Pool),
                Body,
                #{scope => Cluster}
            ),
        T1 = erlang:monotonic_time(millisecond),
        {response, nofin, 200, HeadersResponse} ?= gun_pool:await(GunRef, Timeout),
        Timeout1 = Timeout - (erlang:monotonic_time(millisecond) - T1),
        {ok, Msg, HeadersTrailers} ?= gun_pool:await_body(GunRef, Timeout1),
        {ok, Status} ?= temporal_sdk_grpc_adapter_gun_common:fetch_status(HeadersTrailers),
        case Status of
            0 ->
                {ok, Pool, Msg, HeadersResponse};
            S ->
                {request_error, Pool, #{
                    grpc_response_status => S,
                    grpc_response_headers => HeadersResponse,
                    grpc_response_trailers => HeadersTrailers
                }}
        end
    else
        {response, fin, 200, HeadersErrResponse} ->
            {request_error, Pool, #{grpc_response_headers => HeadersErrResponse}};
        {error, Err} ->
            {request_error, Pool, {grpc_error, Err}};
        {error, Reason, Err} ->
            {request_error, Pool, {grpc_error, Reason, Err}};
        Err ->
            {request_error, Pool, {grpc_error, Err}}
    end.

add_host_header(Headers, Pool) when is_map(Headers) ->
    Headers#{~"host" => Pool};
add_host_header(Headers, Pool) when is_list(Headers) ->
    [{~"host", Pool} | Headers].

-spec start_pool(
    Cluster :: temporal_sdk_grpc:cluster_name(),
    Endpoint :: temporal_sdk_grpc_adapter_gun_common:endpoint(),
    PoolSize :: pos_integer()
) -> binary() | [].
start_pool(Cluster, {HostPort, Host, Port, Opts}, PoolSize) when is_map(Opts) ->
    case
        gun_pool:start_pool(Host, Port, #{conn_opts => Opts, scope => Cluster, size => PoolSize})
    of
        {ok, _Pid} ->
            HostPort;
        Err ->
            temporal_sdk_utils_logger:log_error(
                Err, ?MODULE, ?FUNCTION_NAME, "Error starting gun pool.", #{
                    host => Host, port => Port, opts => Opts, pool_size => PoolSize
                }
            ),
            []
    end.

pick_pool(Cluster) ->
    Pools = temporal_sdk_grpc_adapter_gun_common:get_config(?MODULE, Cluster),
    % eqwalizer:ignore
    OperationalPools = fetch_operational_gun_pools(Cluster, Pools),
    L = length(OperationalPools),
    if
        L == 1 ->
            hd(OperationalPools);
        L > 1 ->
            lists:nth(rand:uniform(L), OperationalPools);
        true ->
            % eqwalizer:ignore
            lists:nth(rand:uniform(length(Pools)), Pools)
    end.

-spec fetch_operational_gun_pools(Cluster :: temporal_sdk_grpc:cluster_name(), [binary()]) ->
    [binary()].
fetch_operational_gun_pools(Cluster, Pools) ->
    fetch_operational_gun_pools(Cluster, Pools, []).

fetch_operational_gun_pools(Cluster, [P | Pools], Acc) ->
    Acc1 =
        case gun_pool:info(P, Cluster) of
            {operational, _Params} -> [P | Acc];
            _ -> Acc
        end,
    fetch_operational_gun_pools(Cluster, Pools, Acc1);
fetch_operational_gun_pools(_Cluster, [], Acc) ->
    Acc.
