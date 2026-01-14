SDK node configuration and management module.

The SDK node is a top level SDK library supervisor process running on the Erlang node.

SDK node responsibilities:

- configure and start SDK node-level statistics telemetry poller,
- configure SDK node-level fixed window rate limiter time windows,
- configure and attach SDK-wide telemetry events handlers,
- configure SDK node-wide options, such as `scope_config`,
- configure, start and supervise [workflow execution scope](architecture.md#workflow-execution-scope)
  processes,
- configure, start and supervise [SDK cluster](`m:temporal_sdk_cluster`) processes.

## SDK Configuration

**`node`** - property list or map with SDK node configuration options as described in the
[SDK Node Configuration](#module-sdk-node-configuration) section.
Example:
<!-- tabs-open -->
### Elixir

```elixir
node: %{:scope_config => [{:cluster_1, 5}]}
```

### Erlang

```erlang
{node, #{scope_config => [{cluster_1, 5}]}}
```
<!-- tabs-close -->

**`clusters`** - property list containing SDK cluster configurations.
The proplist key is a cluster name `t:temporal_sdk_cluster:cluster_name/0`, and the proplist value
is a cluster configuration defined as a map or proplist.
Refer to `m:temporal_sdk_cluster` for details about SDK cluster configuration.

Example `temporal_sdk` configuration with one SDK cluster `cluster_1` and workflow execution scope
shard size set to 5:

<!-- tabs-open -->
### Elixir

```elixir
config :temporal_sdk,
  node: %{:scope_config => [{:cluster_1, 5}]},
  clusters: [
    cluster_1: [
      activities: [%{:task_queue => "default"}],
      workflows: [%{:task_queue => "default"}]
    ]
  ]
```

### Erlang

```erlang
{temporal_sdk, [
    {node, #{scope_config => [{cluster_1, 5}]}},
    {clusters, [
        {cluster_1, [
            {activities, [#{task_queue => "default"}]},
            {workflows, [#{task_queue => "default"}]}
            ]}
        ]}
]}
```
<!-- tabs-close -->

## SDK Node Configuration

**`enable_single_distributed_workflow_execution`** - enables single workflow execution per Erlang
cluster, see [SDK Architecture - Workflow Execution Scope](architecture.md#workflow-execution-scope)
for details.
Setting can be overwritten for each SDK cluster individually by using the SDK cluster
configuration option with the same name, see `m:temporal_sdk_cluster`.
Default: `true`.

**`scope_config`** - SDK node workflow execution scope configuration defined as a property list.
Proplist key is the `workflow_scope` scope name set in the SDK cluster configuration and the
proplist value is the given cluster scope shards count.
If `workflow_scope` option is not set in the cluster configuration, the scope name will be the same
as the cluster name.
See [SDK Architecture - Workflow Execution Scope](architecture.md#workflow-execution-scope) section for
details.
Setting must be consistent across all Erlang cluster SDK nodes.
By default, the shards count is set to 10 for each SDK cluster. Example: `[{cluster_1, 20}]`.

**`limiter_time_windows`** - SDK node fixed window rate limiter time windows configuration.
Values specified here also serve as the time intervals at which telemetry events
[`[temporal_sdk, task_counter, node]`](`m:temporal_sdk_telemetry#module-temporal_sdk-task_counter-node`)
are emitted.
See `m:temporal_sdk_limiter#module-concurrency-and-fixed-window-rate-limiters` for details.
By default, the fixed window rate limiter time window is set to 60 seconds:

<!-- tabs-open -->

### Elixir

```elixir
[
  activity_direct: 60_000,
  activity_eager: 60_000,
  activity_regular: 60_000,
  activity_session: 60_000,
  nexus: 60_000,
  workflow: 60_000
]

```

### Erlang

```erlang
[
  {activity_direct, 60_000},
  {activity_eager, 60_000},
  {activity_regular, 60_000},
  {activity_session, 60_000},
  {nexus, 60_000},
  {workflow, 60_000}
]
```
<!-- tabs-close -->

**`telemetry_poll_interval`** - the time interval at which the SDK node telemetry poller polls for
SDK node statistics and emits
[`[temporal_sdk, node, stats]`](`m:temporal_sdk_telemetry#module-temporal_sdk-node-stats`)
telemetry event.
Default poll time interval is 10 seconds.

**`telemetry_events_handlers`** - telemetry events handlers.
See `t:temporal_sdk_telemetry:events_handlers/0` for details.
By default, all SDK telemetry events with the `exception` suffix are logged with the `error` log
level using the built-in telemetry event handler function `temporal_sdk_telemetry:handle_log/4`:

```erlang
[
    {
        fun() -> temporal_sdk_telemetry:events_by_suffix([exception]) end,
        fun temporal_sdk_telemetry:handle_log/4
    }
]
```
