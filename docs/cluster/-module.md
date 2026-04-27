SDK cluster configuration and management module.

The SDK cluster is a supervised group of processes that facilitates SDK interaction with the
(clustered) Temporal service Temporal server(s).
Interaction includes polling and processing Temporal task executions and handling
gRPC [Temporal API](https://github.com/temporalio/api) services.
SDK cluster supervisors are supervised by the SDK node supervisor.
SDK cluster supervisor supervises [task workers](`m:temporal_sdk_worker`).
SDK cluster can only be started at runtime and cannot be started dynamically.

SDK cluster responsibilities:

- configure and start the SDK cluster statistics telemetry poller,
- configure SDK cluster-level fixed window rate limiter time windows,
- configure SDK cluster-specific options, such as `workflow_scope`,
- configure, start and supervise the gRPC client connections pool connecting to the Temporal server(s),
- configure, start and supervise task worker processes.

## SDK Cluster Configuration

**`cluster`** - [cluster-specific configuration options](#module-cluster-specific-configuration).

**`client`** - [SDK gRPC client](`m:temporal_sdk_client`) configuration.

**`activities`** - list of runtime activity [task workers](`m:temporal_sdk_worker`).

**`nexuses`** - list of runtime nexus [task workers](`m:temporal_sdk_worker`).

**`workflows`** - list of runtime workflow [task workers](`m:temporal_sdk_worker`).

Example `cluster_1` SDK cluster configuration:

<!-- tabs-open -->
### Elixir

```elixir
config :temporal_sdk,
  clusters: [
    cluster_1: [
      cluster: [telemetry_poll_interval: {20, :second}],
      client: %{
        :adapter =>
          {:temporal_sdk_grpc_adapter_gun_pool, [{:endpoints, [{{127, 0, 0, 1}, 7233}]}]}
      },
      activities: [[task_queue: "activity_tq1"], [task_queue: "activity_tq2"]],
      nexuses: [[task_queue: "nexus_tq"]],
      workflows: [[task_queue: "workflow_tq"]]
    ]
  ]
```

### Erlang

```erlang
{temporal_sdk, [
    {clusters, [
        {cluster_1, [
            {cluster, [{telemetry_poll_interval, {20, second}}]},
            {client, #{
                adapter =>
                    {temporal_sdk_grpc_adapter_gun_pool, [
                        {endpoints, [{{127, 0, 0, 1}, 7233}]}
                    ]}
            }},
            {activities, [[{task_queue, "activity_tq1"}], [{task_queue, "activity_tq2"}]]},
            {nexuses, [[{task_queue, "nexus_tq"}]]},
            {workflows, [[{task_queue, "workflow_tq"}]]}
        ]}
    ]}
]}
```
<!-- tabs-close -->

Example configuration above sets the following options for the `cluster_1` SDK cluster:

- `telemetry_poll_interval` is set to 20 seconds,
- the [SDK gRPC client](`m:temporal_sdk_client`) will utilize the `m:temporal_sdk_grpc_adapter_gun_pool`
  HTTP/2 adapter to connect to the Temporal server running on `127.0.0.1:7233`,
- two activity runtime task workers are started to poll Temporal server on `"activity_tq1"` and
  `"activity_tq2"` activity task queues,
- nexus runtime task worker is started to poll Temporal server on `"nexus_tq"` nexus task queue,
- workflow runtime task worker is started to poll Temporal server on `"workflow_tq"` workflow task queue.

Multiple *virtual* SDK clusters can be configured, each with its own cluster-specific configuration,
connecting to the same Temporal server.

[SDK Samples](https://github.com/andrzej-mag/temporal_sdk_samples)
[Payload Converter](https://github.com/andrzej-mag/temporal_sdk_samples/tree/main/docs/payload_converter.md)
example demonstrates virtual clusters usage.

## Cluster-Specific Configuration

**`enable_single_distributed_workflow_execution`** - enables single workflow execution per SDK
cluster, see [SDK Architecture - Workflow Execution Scope](architecture.md#workflow-execution-scope)
for details.
If not set, the value is inherited from the top-level SDK node
`enable_single_distributed_workflow_execution` configuration option, which is set to `true` by default.

**`limiter_time_windows`** - SDK cluster-level fixed window rate limiter time windows configuration.
Values specified here also serve as the time intervals at which telemetry events
[`[temporal_sdk, task_counter, cluster]`](`m:temporal_sdk_telemetry#module-temporal_sdk-task_counter-cluster`)
are emitted.
By default, the fixed window rate limiter time window is set to 60 seconds. See also
`m:temporal_sdk_node#module-sdk-node-configuration` `limiter_time_windows` configuration option and
`m:temporal_sdk_limiter#module-concurrency-and-fixed-window-rate-limiters`.

**`telemetry_poll_interval`** - the time interval at which the SDK cluster telemetry poller polls for
SDK cluster statistics and emits
[`[temporal_sdk, cluster, stats]`](`m:temporal_sdk_telemetry#module-temporal_sdk-cluster-stats`)
telemetry event.
Default poll time interval is 10 seconds.

**`workflow_scope`** - the name of the workflow scope for the given cluster.
Used in the SDK node `scope_config` configuration option. By default, it is set to the cluster name.
