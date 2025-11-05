-module(temporal_sdk_grpc_opts).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    init_opts/2,
    get_adapter/1,
    check_opts/1
]).

-spec init_opts(Cluster :: temporal_sdk_grpc:cluster_name(), AdapterModule :: module()) -> ok.
init_opts(Cluster, AdapterModule) ->
    persistent_term:put({?MODULE, adapter_module, Cluster}, AdapterModule).

-spec get_adapter(Cluster :: temporal_sdk_grpc:cluster_name()) -> AdapterModule :: module().
get_adapter(Cluster) ->
    persistent_term:get({?MODULE, adapter_module, Cluster}).

%% -------------------------------------------------------------------------------------------------
%% private

-spec check_opts(map()) -> ok | {error, {invalid_opts, map()}}.
check_opts(Opts) -> check_opts(proplists:from_map(Opts), []).

-spec check_opts(proplists:proplist(), proplists:proplist()) -> ok | {error, {invalid_opts, map()}}.
check_opts([{converter, {M, _}} | Opts], Acc) when is_atom(M); M == [] ->
    check_opts(Opts, Acc);
check_opts([{codec, {C, _, _}} | Opts], Acc) when is_atom(C) ->
    check_opts(Opts, Acc);
check_opts([{compressor, {C, _, _}} | Opts], Acc) when is_atom(C) ->
    check_opts(Opts, Acc);
check_opts([{interceptor, {I, _, _}} | Opts], Acc) when is_atom(I) ->
    check_opts(Opts, Acc);
check_opts([{timeout, T} | Opts], Acc) when is_integer(T), T >= 0 ->
    check_opts(Opts, Acc);
check_opts([{retry_policy, R} | Opts], Acc) when is_map(R); R =:= disabled ->
    check_opts(Opts, Acc);
check_opts([{headers, H} | Opts], Acc) when is_list(H); is_map(H) ->
    check_opts(Opts, Acc);
check_opts([{maximum_request_size, S} | Opts], Acc) when is_integer(S), S > 0 ->
    check_opts(Opts, Acc);
check_opts([Invalid | Opts], Acc) ->
    check_opts(Opts, [Invalid | Acc]);
check_opts([], []) ->
    ok;
check_opts([], Acc) ->
    {error, {invalid_opts, proplists:to_map(Acc)}}.
