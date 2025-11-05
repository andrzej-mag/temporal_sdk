%% Base tests with single cluster and single configuration

%% Single Temporal Endpoint
-define(CONFIGS_BASE, [
    [
        {clusters, [{temporal_sdk_test_cluster_1, lists:nth(1, ?CONFIGS_BASE_CONFIGS)}]}
    ]
]).

%% Integration tests with _single_ cluster and _single_ configuration
% -define(CONFIGS_INTEGRATION, ?CONFIGS_BASE).

%% Load balancer tests with permutations of:
%%   - clusters number,
%%   - endpoints configuration.
-define(CONFIGS_LB, [
    %% covered by CONFIGS_BASE:
    %% [
    %%     {clusters, [{temporal_sdk_test_cluster_1, lists:nth(1, ?CONFIGS_BASE_CONFIGS)}]}
    %% ],
    [
        {clusters, [{temporal_sdk_test_cluster_2, lists:nth(2, ?CONFIGS_BASE_CONFIGS)}]}
    ],
    [
        {clusters, [{temporal_sdk_test_cluster_3, lists:nth(3, ?CONFIGS_BASE_CONFIGS)}]}
    ],
    [
        {clusters, [
            {temporal_sdk_test_cluster_1, lists:nth(1, ?CONFIGS_BASE_CONFIGS)},
            {temporal_sdk_test_cluster_2, lists:nth(2, ?CONFIGS_BASE_CONFIGS)}
        ]}
    ],
    [
        {clusters, [
            {temporal_sdk_test_cluster_2, lists:nth(2, ?CONFIGS_BASE_CONFIGS)},
            {temporal_sdk_test_cluster_3, lists:nth(3, ?CONFIGS_BASE_CONFIGS)}
        ]}
    ],
    [
        {clusters, [
            {temporal_sdk_test_cluster_1, lists:nth(1, ?CONFIGS_BASE_CONFIGS)},
            {temporal_sdk_test_cluster_3, lists:nth(3, ?CONFIGS_BASE_CONFIGS)}
        ]}
    ],
    [
        {clusters, [
            {temporal_sdk_test_cluster_1, lists:nth(1, ?CONFIGS_BASE_CONFIGS)},
            {temporal_sdk_test_cluster_2, lists:nth(2, ?CONFIGS_BASE_CONFIGS)},
            {temporal_sdk_test_cluster_3, lists:nth(3, ?CONFIGS_BASE_CONFIGS)}
        ]}
    ]
]).

-define(CONFIGS_BASE_CONFIGS, [
    [
        {client, #{
            endpoints => lists:nth(1, ?ENDPOINTS), grpc_opts => ?CONFIGS_BASE_GRPC_OPTS
        }},
        {activities, [?CONFIGS_BASE_TASK]},
        {workflows, [?CONFIGS_BASE_TASK]}
    ],
    [
        {client, #{
            endpoints => lists:nth(2, ?ENDPOINTS), grpc_opts => ?CONFIGS_BASE_GRPC_OPTS
        }},
        {activities, [?CONFIGS_BASE_TASK]},
        {workflows, [?CONFIGS_BASE_TASK]}
    ],
    [
        {client, #{
            endpoints => lists:nth(3, ?ENDPOINTS), grpc_opts => ?CONFIGS_BASE_GRPC_OPTS
        }},
        {activities, [?CONFIGS_BASE_TASK]},
        {workflows, [?CONFIGS_BASE_TASK]}
    ]
]).

-define(CONFIGS_BASE_TASK, #{
    namespace => ?NAMESPACE,
    task_queue => ?TASK_QUEUE_NAME,
    task_poller_pool_size => 0
}).

-define(CONFIGS_BASE_GRPC_OPTS, #{}).

%% -------------------------------------------------------------------------------------------------
%% Multi-config tests with 3 clusters and permutations of:
%%   - gRPC options,
%%   - workflows,
%%   - activities.

-define(CONFIGS_MULTI, [
    [
        {clusters, [
            {temporal_sdk_test_cluster_1, Config},
            {temporal_sdk_test_cluster_2, lists:nth(2, ?CONFIGS_BASE_CONFIGS)},
            {temporal_sdk_test_cluster_3, lists:nth(3, ?CONFIGS_BASE_CONFIGS)}
        ]}
    ]
 || Config <- ?CONFIGS_MULTI_CONFIGS
]).

-define(CONFIGS_MULTI_CONFIGS, [
    [
        {client, Client},
        {activities, Activities},
        {workflows, Workflows}
    ]
 || Client <- ?CONFIGS_MULTI_CLIENTS,
    Activities <- ?CONFIGS_MULTI_ACTIVITIES,
    Workflows <- ?CONFIGS_MULTI_WORKFLOWS
]).

-define(CONFIGS_MULTI_CLIENTS, [
    #{
        endpoints => Endpoint,
        grpc_opts => RequestOpts,
        pool_strategy => PoolStrategy
    }
 || Endpoint <- ?ENDPOINTS,
    RequestOpts <- ?CONFIGS_MULTI_GRPC_OPTS,
    PoolStrategy <- ?CONFIGS_MULTI_POOL_STRATEGIES
]).

-define(CONFIGS_MULTI_POOL_STRATEGIES, [random, round_robin]).

-define(CONFIGS_MULTI_GRPC_OPTS, [
    #{
        converter => Converter,
        codec => Codec,
        compressor => Compressor,
        retry_policy => RetryPolicy
    }
 || Converter <- ?CONFIGS_MULTI_CONVERTERS,
    Codec <- ?CONFIGS_MULTI_CODECS,
    Compressor <- ?CONFIGS_MULTI_COMPRESSORS,
    RetryPolicy <- ?CONFIGS_MULTI_RETRY_POLICIES
]).

-define(CONFIGS_MULTI_CONVERTERS, [
    {temporal_sdk_proto_converter, [temporal_sdk_codec_payload_erl]},
    {temporal_sdk_proto_converter,
        {
            [
                temporal_sdk_codec_payload_binary,
                temporal_sdk_codec_payload_json,
                temporal_sdk_codec_payload_erl
            ],
            [
                {
                    [
                        temporal_sdk_codec_payload_text
                    ],
                    [
                        'temporal.api.failure.v1.ApplicationFailureInfo',
                        'temporal.api.failure.v1.CanceledFailureInfo',
                        'temporal.api.failure.v1.ResetWorkflowFailureInfo',
                        'temporal.api.failure.v1.TimeoutFailureInfo'
                    ]
                }
            ]
        }}
]).

-define(CONFIGS_MULTI_CODECS, [
    {temporal_sdk_codec_binaries, [], []},
    {temporal_sdk_codec_binaries_copied, [], []},
    {temporal_sdk_codec_strings, [], []},
    {temporal_sdk_codec_strings_copied, [], []}
]).

-define(CONFIGS_MULTI_COMPRESSORS, [
    {temporal_sdk_grpc_compressor_gzip, [], []},
    {temporal_sdk_grpc_compressor_identity, [], []}
]).

-define(CONFIGS_MULTI_RETRY_POLICIES, [
    disabled,
    #{
        max_attempts => 3,
        backoff_coefficient => 1,
        initial_interval => 50,
        maximum_interval => 100,
        is_retryable => fun temporal_sdk_api:is_retryable/3
    }
]).

-define(CONFIGS_MULTI_ACTIVITIES, [
    [],
    [
        #{
            namespace => ?NAMESPACE,
            task_queue => "activities_queue_tests_fixtures",
            task_poller_pool_size => 0
        }
    ],
    [
        #{
            namespace => ?NAMESPACE,
            task_queue => "activities_queue_tests_fixtures_1",
            task_poller_pool_size => 0
        },
        #{
            namespace => ?NAMESPACE,
            task_queue => "activities_queue_tests_fixtures_2",
            task_poller_pool_size => 0
        }
    ]
]).

-define(CONFIGS_MULTI_WORKFLOWS, [
    [],
    [
        #{
            namespace => ?NAMESPACE,
            task_queue => "workflows_queue_tests_fixtures",
            task_poller_pool_size => 0
        }
    ],
    [
        #{
            namespace => ?NAMESPACE,
            task_queue => "workflows_queue_tests_fixtures_1",
            task_poller_pool_size => 0
        },
        #{
            namespace => ?NAMESPACE,
            task_queue => "workflows_queue_tests_fixtures_2",
            task_poller_pool_size => 0
        }
    ]
]).
