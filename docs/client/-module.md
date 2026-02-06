SDK gRPC client module.

SDK gRPC client is a supervised gRPC connections pool that connects to the Temporal server
[Frontend Service](https://docs.temporal.io/temporal-service/temporal-server#frontend-service)
gRPC service handler port (default 7233).
Each [SDK cluster](`m:temporal_sdk_cluster`) owns its individual SDK gRPC client.

## SDK gRPC Client Configuration

**`adapter`** - `t:temporal_sdk_grpc:adapter/0` configuration of the HTTP/2 adapter used to handle
gRPC requests. Default: `{temporal_sdk_grpc_adapter_gun, []}`.

**`pool_size`** - gRPC client connection pool size.
When increasing the connection pool size, also consider increasing the OS file descriptor (FD) limits.
Default: `10`.

**`pool_strategy`** - gRPC client connection pool strategy, one of: `round_robin` or `random`.
Default: `round_robin`.

**`grpc_opts`** - `t:temporal_sdk_grpc:opts/0` gRPC request options for all gRPC requests except
long-poll gRPC requests.

Default:

```erlang
[
    {converter,
        {temporal_sdk_proto_converter, {
            %% default global payload codecs:
            [
                temporal_sdk_codec_payload_binary,
                temporal_sdk_codec_payload_json,
                temporal_sdk_codec_payload_erl
            ],
            %% custom payload codecs defined per messages list:
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
                    ]
                }
            ]
        }}},
    {codec, {temporal_sdk_codec_binaries, [], []}},
    {compressor, {temporal_sdk_grpc_compressor_identity, [], []}},
    {interceptor, {temporal_sdk_grpc_interceptor_identity, [], []}},
    {headers, #{
        <<"te">> => <<"trailers">>,
        <<"user-agent">> => temporal_sdk_utils:worker_version()
    }},
    {timeout, 5_000},
    {retry_policy, #{
        max_attempts => 3,
        backoff_coefficient => 2,
        initial_interval => 100,
        maximum_interval => 1_000,
        is_retryable => fun temporal_sdk_api:is_retryable/3
    }},
    {maximum_request_size, 4_100_000}
]
```

**`grpc_opts_longpoll`** - `t:temporal_sdk_grpc:opts/0` overwrites for gRPC long-poll request options.
Long-poll gRPC request options are evaluated by merging overwrites defined here with the values
provided in the `grpc_opts`.

Temporal gRPC long-poll requests:

- `PollActivityTaskQueue`,
- `PollWorkflowTaskQueue`,
- `PollNexusTaskQueue`.

Default:

```erlang
[
    {timeout, 70_000},
    {retry_policy, disabled}
]
```

**`helpers`** - gRPC request helpers.
See [gRPC Helpers section](`m:temporal_sdk_client#module-grpc-helpers`) below for details.

Default:

```erlang
[
    {id, fun temporal_sdk_api:id/4},
    {identity, fun temporal_sdk_api:identity/3},
    {to_payload_mapper, fun temporal_sdk_api:to_payload_mapper/5},
    {from_payload_mapper, fun temporal_sdk_api:from_payload_mapper/5},
    {serializer, fun temporal_sdk_api:serializer/4}
]
```

## gRPC Helpers

SDK gRPC client gRPC helpers functions must be implemented as non-raising and non-blocking functions.
Violating this requirement will cause SDK failures or unexpected behavior.

**`id`** - `t:temporal_sdk_client:helpers_id_fun/0` function used to generate Temporal API gRPC request
identifiers.
See `temporal_sdk_api:id/4` for the default SDK implementation.

**`identity`** - `t:temporal_sdk_client:helpers_identity_fun/0` function used to generate Temporal API
gRPC request worker or client identities.
See `temporal_sdk_api:identity/3` for the default SDK implementation.

**`to_payload_mapper`** - `t:temporal_sdk_client:to_payload_mapper/0` function mapping from Erlang term
`t:temporal_sdk:term_to_payload/0` to Temporal payload `t:temporal_sdk:temporal_payload/0`.
See `temporal_sdk_api:to_payload_mapper/5` for the default SDK implementation.

**`from_payload_mapper`** - `t:temporal_sdk_client:from_payload_mapper/0` function mapping from
Temporal payload `t:temporal_sdk:temporal_payload/0` to Erlang term
`t:temporal_sdk:term_from_payload/0`.
See `temporal_sdk_api:from_payload_mapper/5` for the default SDK implementation.

**`serializer`** - `t:temporal_sdk_client:helpers_serializer_fun/0` function used to serialize
Erlang terms to Unicode characters before sending them to the Temporal server.
See `temporal_sdk_api:serializer/4` for the default SDK implementation.
