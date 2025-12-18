SDK node configuration and management module.

## SDK Configuration

**`node`** - proplist or map with SDK node configuration options as described in the
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

**`clusters`** - keyword list/proplist containing Temporal cluster configurations.
The list key is a cluster name `t:temporal_sdk_cluster:cluster_name/0`, and the list value is a
cluster configuration represented as a map or proplist.
Refer to `m:temporal_sdk_cluster` for details about cluster configuration.
Example:

<!-- tabs-open -->

### Elixir

```elixir
[
  cluster_1: [
    activities: [%{:task_queue => "default"}],
    workflows: [%{:task_queue => "default"}]
  ]
]
```

### Erlang

```erlang
[
    {cluster_1, [
        {activities, [#{task_queue => "default"}]},
        {workflows, [#{task_queue => "default"}]}
    ]}
]
```
<!-- tabs-close -->

Example `temporal_sdk` configuration using above snippets:

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

### SDK Node Configuration

**`enable_single_distributed_workflow_execution`** - enables single workflow execution per Erlang
cluster, see [SDK node scope](#module-sdk-node-scope) for details.
Default: `true`.

**`scope_config`** - SDK node workflow execution scope configuration. Accepts a keyword
list/proplist, with the list key set to the Temporal cluster name and the value set to the
given cluster scope shards count. See [SDK node scope](#module-sdk-node-scope) section for details.
By default, the shards count is set to 10 for each Temporal cluster. Example: `[{cluster_1, 5}]`.

**`limiter_time_windows`** - SDK node fixed window rate limiter time windows configuration.
See `m:temporal_sdk_limiter` for details.
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
SDK node stats and emits
[`[temporal_sdk, node, stats]`](`m:temporal_sdk_telemetry#module-temporal_sdk-node-stats`)
telemetry event.
Default poll interval is 10 seconds.

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

## SDK Node Scope

After the user starts workflow execution by using
`TemporalSdk.start_workflow/3`/`temporal_sdk:start_workflow/3`,
a start workflow execution request is sent to the Temporal server.
The Temporal server schedules the new workflow task execution on a user-defined workflow task queue.
The workflow task execution is then polled from the Temporal server by the SDK workflow task worker
polling given workflow task queue.
Workflow task workers typically run across multiple user cluster hosts.
After a new workflow task execution is polled, the SDK is responsible for processing the polled
workflow task execution with workflow task executor.
The Temporal server may dispatch the given workflow task execution to one or more hosts running
workflow task workers.

Other Temporal SDK implementations use the concept of
["Worker Task Slots"](https://docs.temporal.io/develop/worker-performance#slots) when processing task
executions. After a new task execution is polled from a task queue by the SDK, task execution is
cached and executed on each host that polled for the new task.
If the Temporal server dispatches a task to multiple user cluster hosts, conventional SDKs will
cache and execute the polled task on each involved worker host. This strategy leads to storing the
same task data and executing the same task code on multiple hosts.

Erlang leverages OTP distribution to optimize Temporal task execution.
If `enable_single_distributed_workflow_execution` configuration option is set to true (default),
after polling a new workflow task execution, the SDK will check whether the given workflow task
execution is already being processed by a workflow task executor on any node within the Erlang cluster.
If there is already a workflow executor processing the given workflow task execution, the polled
workflow task is sent to that workflow executor. The workflow executor then validates received
workflow task integrity by comparing the polled task's event history with its internal executor event
history and continues with the workflow task execution.
If no workflow executors are found processing polled workflow task execution, a new workflow executor
process is spawned on the local node.
In the event of a split-brain state in an Erlang cluster, workflow executors are started on all
isolated Erlang cluster partitions that polled workflow task execution.
Each workflow task executor will progress with workflow task execution until the task transitions to a
closed state or another workflow executor advances the workflow execution further.
The optimization described above is performed on a best-effort basis.
If the Temporal server dispatches workflow task execution to multiple Erlang nodes, at least one
workflow task execution will be processed by the SDK in the Erlang cluster.

SDK uses sharded `m:pg` process groups to register workflow task executors across the Erlang cluster.
`scope_config` SDK node configuration option is used to specify the number of process group shards
per Temporal cluster.
The default number of process group shards is set to 10, which should be sufficient for most use cases.
