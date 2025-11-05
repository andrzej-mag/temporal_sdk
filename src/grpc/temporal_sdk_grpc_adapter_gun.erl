-module(temporal_sdk_grpc_adapter_gun).
-behaviour(temporal_sdk_grpc_adapter).

% elp:ignore W0012 W0040
-moduledoc """
gRPC client adapter using `m:gun`.
""".

-export([
    init_adapter/2,
    pools_status/1,
    request/6
]).

-type endpoint() ::
    {
        Host :: inet:hostname() | inet:ip_address()
    }
    | {
        Host :: inet:hostname() | inet:ip_address(),
        Port :: inet:port_number()
    }
    | {
        Host :: inet:hostname() | inet:ip_address(),
        Port :: inet:port_number(),
        GunOpts :: gun:opts()
    }.
-export_type([endpoint/0]).

-type config() :: [
    {endpoints, [endpoint()]}
    | {gun_opts, gun:opts()}
].
-export_type([config/0]).

-doc false.
-spec init_adapter(Cluster :: temporal_sdk_grpc:cluster_name(), Config :: config()) ->
    ok | {error, term()}.
init_adapter(Cluster, Config) ->
    case temporal_sdk_grpc_adapter_gun_common:init_endpoints(Config) of
        {ok, Endpoints} ->
            temporal_sdk_grpc_adapter_gun_common:set_config(?MODULE, Cluster, Endpoints);
        Err ->
            Err
    end.

-doc false.
-spec pools_status(Cluster :: temporal_sdk_grpc:cluster_name()) -> undefined.
pools_status(_Cluster) -> undefined.

-doc false.
request(Cluster, Method, Path, Headers, Body, Timeout) ->
    {HostPort, Host, Port, Opts} = pick_endpoint(Cluster),
    case gun:open(Host, Port, Opts) of
        {ok, ConnPid} ->
            maybe
                {ok, http2} ?= gun:await_up(ConnPid),
                StreamRef ?= gun:request(ConnPid, Method, Path, Headers, Body),
                T1 = erlang:monotonic_time(millisecond),
                {response, nofin, 200, HeadersResponse} ?= gun:await(ConnPid, StreamRef, Timeout),
                Timeout1 = Timeout - (erlang:monotonic_time(millisecond) - T1),
                {ok, Msg, HeadersTrailers} ?= gun:await_body(ConnPid, StreamRef, Timeout1),
                gun:close(ConnPid),
                {ok, Status} ?= temporal_sdk_grpc_adapter_gun_common:fetch_status(HeadersTrailers),
                case Status of
                    0 ->
                        {ok, HostPort, Msg, HeadersResponse};
                    S ->
                        {request_error, HostPort, #{
                            grpc_response_status => S,
                            grpc_response_headers => HeadersResponse,
                            grpc_response_trailers => HeadersTrailers
                        }}
                end
            else
                {response, fin, 200, HeadersErrResponse} ->
                    gun:close(ConnPid),
                    {request_error, HostPort, #{grpc_response_headers => HeadersErrResponse}};
                {error, Err} ->
                    gun:close(ConnPid),
                    {request_error, HostPort, {grpc_error, Err}};
                Err ->
                    gun:close(ConnPid),
                    {request_error, HostPort, {grpc_error, Err}}
            end;
        Err ->
            {request_error, HostPort, {adapter_error, Err}}
    end.

pick_endpoint(Cluster) ->
    Endpoints = temporal_sdk_grpc_adapter_gun_common:get_config(?MODULE, Cluster),
    % eqwalizer:ignore
    L = length(Endpoints),
    if
        % eqwalizer:ignore
        L =:= 1 -> hd(Endpoints);
        % eqwalizer:ignore
        L > 1 -> lists:nth(rand:uniform(L), Endpoints)
    end.
