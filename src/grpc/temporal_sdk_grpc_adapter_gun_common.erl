-module(temporal_sdk_grpc_adapter_gun_common).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    init_endpoints/1,
    set_config/3,
    get_config/2,
    fetch_status/1
]).

-type endpoint() ::
    {
        HostPort :: binary(),
        Host :: inet:hostname() | inet:ip_address(),
        Port :: inet:port_number(),
        GunOpts :: gun:opts()
    }.
-export_type([endpoint/0]).

-define(DEFAULT_ENDPOINT_HOST, {127, 0, 0, 1}).
-define(DEFAULT_ENDPOINT_PORT, 7233).
-define(DEFAULT_ENDPOINT_OPTS, #{
    protocols => [http2],
    http2_opts => #{keepalive => 30000, keepalive_tolerance => 2},
    tcp_opts => [{keepalive, true}, {nodelay, true}]
}).
-define(DEFAULT_ENDPOINTS, [
    {?DEFAULT_ENDPOINT_HOST, ?DEFAULT_ENDPOINT_PORT, ?DEFAULT_ENDPOINT_OPTS}
]).
-define(DEFAULT_OPTS, ?DEFAULT_ENDPOINT_OPTS).

-spec init_endpoints(Config :: proplists:proplist()) ->
    {ok, [endpoint()]} | {error, Details :: map()}.
init_endpoints(Config) ->
    Endpoints = proplists:get_value(endpoints, Config, ?DEFAULT_ENDPOINTS),
    Opts = maps:merge(?DEFAULT_OPTS, proplists:get_value(gun_opts, Config, ?DEFAULT_OPTS)),
    init_endpoints(Endpoints, Opts, []).

init_endpoints([{Host} | TEndpoints], DefaultOpts, Acc) when
    is_tuple(Host); is_atom(Host); is_list(Host)
->
    init_endpoints(TEndpoints, DefaultOpts, [{Host, ?DEFAULT_ENDPOINT_PORT, DefaultOpts} | Acc]);
init_endpoints([{Host, Port} | TEndpoints], DefaultOpts, Acc) when
    is_integer(Port), Port > 0, Port < 65536, is_tuple(Host); is_atom(Host); is_list(Host)
->
    init_endpoints(TEndpoints, DefaultOpts, [{Host, Port, DefaultOpts} | Acc]);
init_endpoints([{Host, Port, Opts} | TEndpoints], DefaultOpts, Acc) when
    is_map(Opts), is_integer(Port), Port > 0, Port < 65536, is_tuple(Host);
    is_atom(Host);
    is_list(Host)
->
    init_endpoints(TEndpoints, DefaultOpts, [{Host, Port, maps:merge(DefaultOpts, Opts)} | Acc]);
init_endpoints([InvalidEndpoint | _TEndpoints], _DefaultOpts, _Acc) ->
    {error, #{reason => "Invalid endpoint.", invalid_endpoint => InvalidEndpoint}};
init_endpoints([], _DefaultOpts, Acc) ->
    {ok, [{host_port_binary(Host, Port), Host, Port, Opts} || {Host, Port, Opts} <- Acc]}.

-spec set_config(Module :: module(), Cluster :: temporal_sdk_grpc:cluster_name(), Config :: term()) ->
    ok.
set_config(Module, Cluster, Config) ->
    persistent_term:put({Module, adapter_config, Cluster}, Config).

-spec get_config(Module :: module(), Cluster :: temporal_sdk_grpc:cluster_name()) ->
    Config :: term().
get_config(Module, Cluster) ->
    persistent_term:get({Module, adapter_config, Cluster}).

-spec fetch_status([{binary(), binary()}]) -> {ok, non_neg_integer()} | {error, Details :: map()}.
fetch_status(HeadersTrailers) ->
    case proplists:get_value(~"grpc-status", HeadersTrailers, '$undefined') of
        S when is_binary(S) ->
            try
                {ok, binary_to_integer(S)}
            catch
                error:badarg ->
                    {error, #{
                        reason => "Invalid <grpc-status> header type - expected integer as binary.",
                        invalid_headers => HeadersTrailers
                    }}
            end;
        _ ->
            {error, #{
                reason => "Invalid gRPC response headers: missing or invalid <grpc-status>.",
                invalid_headers => HeadersTrailers
            }}
    end.

-spec host_port_binary(
    Host :: inet:hostname() | inet:ip_address() | binary(), Port :: inet:port_number()
) -> binary().
host_port_binary(Host, Port) when is_list(Host) ->
    host_port_binary(list_to_binary(Host), Port);
host_port_binary(Host, Port) when is_atom(Host) ->
    host_port_binary(atom_to_binary(Host), Port);
host_port_binary(Host, Port) when is_tuple(Host) ->
    case inet:ntoa(Host) of
        {error, einval} -> host_port_binary(~"invalid", Port);
        A -> host_port_binary(A, Port)
    end;
host_port_binary(Host, Port) when is_binary(Host) andalso is_integer(Port) ->
    P = integer_to_binary(Port),
    <<Host/binary, ":", P/binary>>.
