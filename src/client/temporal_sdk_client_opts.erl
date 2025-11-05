-module(temporal_sdk_client_opts).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    init_opts/2,
    get_opts/1,
    pick_worker_id/1
]).

-define(DEFAULT_GRPC_OPTS_CONVERTER,
    {temporal_sdk_proto_converter, {
        %% default global codecs
        [
            temporal_sdk_codec_payload_binary,
            temporal_sdk_codec_payload_json,
            temporal_sdk_codec_payload_erl
        ],
        %% custom codecs defined per messages list
        [
            {
                %% failure codecs
                [
                    temporal_sdk_codec_payload_text
                ],
                %% failure messages
                [
                    'temporal.api.failure.v1.ApplicationFailureInfo',
                    'temporal.api.failure.v1.CanceledFailureInfo',
                    'temporal.api.failure.v1.ResetWorkflowFailureInfo',
                    'temporal.api.failure.v1.TimeoutFailureInfo'
                    % {'some.message', some_key}
                ]
            }
        ]
    }}
).

%% example single codecs definition:
% -define(DEFAULT_GRPC_OPTS_CONVERTER,
%     {temporal_sdk_proto_converter, [
%         temporal_sdk_codec_payload_binary,
%         temporal_sdk_codec_payload_json,
%         temporal_sdk_codec_payload_erl
%     ]}
% ).

-define(DEFAULT_GRPC_OPTS_CODEC, {temporal_sdk_codec_binaries, [], []}).
%% Alternative:
%% -define(DEFAULT_GRPC_OPTS_CODEC, {temporal_sdk_codec_strings, [], []}).

-define(DEFAULT_GRPC_OPTS_COMPRESSOR, {temporal_sdk_grpc_compressor_identity, [], []}).

-define(DEFAULT_GRPC_OPTS_INTERCEPTOR, {temporal_sdk_grpc_interceptor_identity, [], []}).

-define(DEFAULT_GRPC_OPTS_RETRY_POLICY, #{
    max_attempts => 3,
    backoff_coefficient => 2,
    initial_interval => 100,
    maximum_interval => 1_000,
    is_retryable => fun temporal_sdk_api:is_retryable/3
}).

-define(DEFAULT_GRPC_OPTS_HEADERS, #{
    <<"te">> => <<"trailers">>,
    <<"user-agent">> => temporal_sdk_utils:worker_version()
}).

%% Maximum gRPC receive message size is: 4MB -> 4_194_304 B.
%% To accomodate differences in message size estimation we use a slightly lower number.
-define(DEFAULT_GRPC_OPTS_MAXIMUM_REQUEST_SIZE, 4_100_000).

%% -------------------------------------------------------------------------------------------------
%% public

-spec init_opts(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Opts :: temporal_sdk_client:opts() | temporal_sdk_client:user_opts()
) ->
    {ok, temporal_sdk_client:opts()} | {error, {invalid_opts, Reason :: term()}}.
init_opts(Cluster, ClientOpts) ->
    case temporal_sdk_utils_opts:build(defaults(user_opts), ClientOpts) of
        {ok, Opts} ->
            persist_opts(Cluster, Opts),
            persist_pool_strategy(Cluster, Opts),
            {ok, Opts};
        Err ->
            Err
    end.

defaults(user_opts) ->
    [
        {adapter, tuple, {temporal_sdk_grpc_adapter_gun, []}},
        {pool_size, pos_integer, 10},
        {pool_strategy, atom, round_robin},
        {grpc_opts, nested, defaults(grpc_opts)},
        {grpc_opts_longpoll, nested, defaults(grpc_opts_longpoll)},
        {helpers, nested, defaults(helpers)}
    ];
defaults(grpc_opts) ->
    [
        {converter, tuple, ?DEFAULT_GRPC_OPTS_CONVERTER},
        {codec, tuple, ?DEFAULT_GRPC_OPTS_CODEC},
        {compressor, tuple, ?DEFAULT_GRPC_OPTS_COMPRESSOR},
        {interceptor, tuple, ?DEFAULT_GRPC_OPTS_INTERCEPTOR},
        {headers, map, ?DEFAULT_GRPC_OPTS_HEADERS, merge},
        {timeout, pos_integer, 5_000},
        {retry_policy, map, ?DEFAULT_GRPC_OPTS_RETRY_POLICY, merge},
        {maximum_request_size, pos_integer, ?DEFAULT_GRPC_OPTS_MAXIMUM_REQUEST_SIZE}
    ];
defaults(grpc_opts_longpoll) ->
    [
        {converter, tuple, ?DEFAULT_GRPC_OPTS_CONVERTER},
        {codec, tuple, ?DEFAULT_GRPC_OPTS_CODEC},
        {compressor, tuple, ?DEFAULT_GRPC_OPTS_COMPRESSOR},
        {interceptor, tuple, ?DEFAULT_GRPC_OPTS_INTERCEPTOR},
        {headers, map, ?DEFAULT_GRPC_OPTS_HEADERS, merge},
        {timeout, pos_integer, 70_000},
        {retry_policy, [atom, map], disabled},
        {maximum_request_size, pos_integer, ?DEFAULT_GRPC_OPTS_MAXIMUM_REQUEST_SIZE}
    ];
defaults(helpers) ->
    [
        {id, function, fun temporal_sdk_api:id/4},
        {identity, function, fun temporal_sdk_api:identity/3},
        {to_payload_mapper, function, fun temporal_sdk_api:to_payload_mapper/5},
        {from_payload_mapper, function, fun temporal_sdk_api:from_payload_mapper/5},
        {serializer, function, fun temporal_sdk_api:serializer/4}
    ].

-spec get_opts(Cluster :: temporal_sdk_cluster:cluster_name()) ->
    {ok, temporal_sdk_client:opts()} | {error, invalid_cluster}.
get_opts(Cluster) ->
    case persistent_term:get({?MODULE, opts, Cluster}, undefined) of
        undefined -> {error, invalid_cluster};
        Opts -> {ok, Opts}
    end.

-spec pick_worker_id(Cluster :: temporal_sdk_cluster:cluster_name()) ->
    {ok, pos_integer()}
    | {error, invalid_cluster}
    | {error, {invalid_opts, Reason :: term()}}.
pick_worker_id(Cluster) ->
    case get_opts(Cluster) of
        {ok, #{pool_size := PoolSize, pool_strategy := PoolStrategy}} ->
            case PoolStrategy of
                random ->
                    {ok, rand:uniform(PoolSize)};
                round_robin ->
                    Counter = persistent_term:get({?MODULE, worker_pool_counter, Cluster}),
                    {ok, (atomics:add_get(Counter, 1, 1) rem PoolSize) + 1}
            end;
        {ok, _Opts} ->
            {error, {invalid_opts, "Missing <pool_size> or <pool_strategy> keys."}};
        Err ->
            Err
    end.

%% -------------------------------------------------------------------------------------------------
%% private

persist_opts(Cluster, Opts) ->
    persistent_term:put({?MODULE, opts, Cluster}, Opts).

persist_pool_strategy(_Cluster, #{pool_strategy := random}) ->
    ok;
persist_pool_strategy(Cluster, #{pool_strategy := round_robin}) ->
    persistent_term:put(
        {?MODULE, worker_pool_counter, Cluster}, atomics:new(1, [{signed, false}])
    ).
