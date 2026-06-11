SDK telemetry module.

## Common Event Measurements and Metadata

Telemetry event `system_time` measurement is set to `erlang:system_time()`.

Telemetry event `duration` measurement is expressed in native `t:erlang:time_unit/0`.

All `start` and `init` telemetry events contain `system_time` as a measurement.

All `stop` and `exception` telemetry events contain `duration` as a measurement.

Exception metadata common to all `exception` telemetry events:

- `class` - one of `error`, `exit` or `throw`,
- `reason` - exception reason, any Erlang `term()`,
- `stacktrace` - OTP style stack trace, see `erlang:raise/3`.

## SDK Node - `m:temporal_sdk_node`

### `[temporal_sdk, node, init]`

Emitted when the SDK node supervisor is initialized.

**Metadata**

- `opts` - user-provided `node` SDK configuration options

<hr>

### `[temporal_sdk, node, start]`

Emitted when the SDK node supervisor has been successfully initialized and is started.

**Metadata**

- `opts` - parsed `node` SDK configuration options

<hr>

### `[temporal_sdk, node, stats]`

SDK node stats emitted every `telemetry_poll_interval` time interval set with
[SDK node configuration](`m:temporal_sdk_node#module-sdk-node-configuration`).

**Measurements**

- `clusters_count` - equal to `length(temporal_sdk_cluster:list())`
- `clusters_list` - equal to `temporal_sdk_cluster:list()`
- `os_stats` - equal to `temporal_sdk_node:os_stats()`
- `stats` - equal to `temporal_sdk_node:stats()`

## SDK Cluster - `m:temporal_sdk_cluster`

Metadata common to all SDK cluster telemetry events:

- `cluster` - cluster name `t:temporal_sdk_cluster:cluster_name/0`

<hr>

### `[temporal_sdk, cluster, init]`

Emitted when the SDK cluster supervisor is initialized.

**Metadata**

- `opts` - user-provided SDK cluster `t:temporal_sdk_cluster:cluster_config/0` configuration

<hr>

### `[temporal_sdk, cluster, start]`

Emitted when the SDK cluster supervisor has been successfully initialized and is started.

**Metadata**

- `opts` - parsed SDK cluster configuration

<hr>

### `[temporal_sdk, cluster, exception]`

Emitted when the SDK cluster supervisor fails to start.

**Metadata**

- `error` - reason for failure
- `opts` - user-provided SDK cluster `t:temporal_sdk_cluster:cluster_config/0` configuration

<hr>

### `[temporal_sdk, cluster, stats]`

SDK cluster stats emitted every `telemetry_poll_interval` time interval set with
[SDK cluster-specific configuration](`m:temporal_sdk_cluster#module-cluster-specific-configuration`).

**Measurements**

- `activity_count` - number of activity task workers
- `activity_list` - list of activity task workers
- `nexus_count` - number of nexus task workers
- `nexus_list` - list of nexus task workers
- `stats` - equal to `temporal_sdk_cluster:stats/1`
- `workflow_count` - number of workflow task workers
- `workflow_list` - list of workflow task workers

Example measurements:

```erlang
#{stats =>
      #{nexus => 0,workflow => 1,activity_session => 0,activity_regular => 1,
        activity_eager => 0,activity_direct => 0},
  activity_list => ["a1"],
  activity_count => 1,
  nexus_list => ["n1"],
  nexus_count => 1,
  workflow_list => [w1],
  workflow_count => 1}
```

## Task Worker - `m:temporal_sdk_worker`

- [temporal_sdk, worker, init]
- [temporal_sdk, worker, start]
- [temporal_sdk, worker, stop]
- [temporal_sdk, worker, exception]
- [temporal_sdk, worker, stats]

## Activity Task - `m:temporal_sdk_activity`

- [temporal_sdk, activity, executor, start]
- [temporal_sdk, activity, executor, stop]
- [temporal_sdk, activity, executor, exception]
- [temporal_sdk, activity, task, start]
- [temporal_sdk, activity, task, stop]
- [temporal_sdk, activity, task, exception]
- [temporal_sdk, activity, execution, start]
- [temporal_sdk, activity, execution, stop]
- [temporal_sdk, activity, execution, exception]

## Nexus Task - `m:temporal_sdk_nexus`

- [temporal_sdk, nexus, executor, start]
- [temporal_sdk, nexus, executor, stop]
- [temporal_sdk, nexus, executor, exception]
- [temporal_sdk, nexus, task, start]
- [temporal_sdk, nexus, task, stop]
- [temporal_sdk, nexus, task, exception]
- [temporal_sdk, nexus, execution, start]
- [temporal_sdk, nexus, execution, stop]
- [temporal_sdk, nexus, execution, exception]

## Workflow Task - `m:temporal_sdk_workflow`

- [temporal_sdk, workflow, executor, start]
- [temporal_sdk, workflow, executor, stop]
- [temporal_sdk, workflow, executor, exception]
- [temporal_sdk, workflow, task, start]
- [temporal_sdk, workflow, task, stop]
- [temporal_sdk, workflow, task, exception]
- [temporal_sdk, workflow, execution, start]
- [temporal_sdk, workflow, execution, stop]
- [temporal_sdk, workflow, execution, exception]
- [temporal_sdk, workflow, marker, start]
- [temporal_sdk, workflow, marker, stop]
- [temporal_sdk, workflow, marker, exception]

## Task Poller - `temporal_sdk_poller`

Metadata common to all task poller telemetry events:

- `cluster` - SDK cluster name `t:temporal_sdk_cluster:cluster_name/0`
- `namespace` - Temporal namespace name
- `poller_id` - task poller process unique id defined as a list:
  `[WorkerSupervisorPid, WorkerPollerId]`. `WorkerPollerId` is an integer in the range from 1 to
  task worker pollers pool size, for example: `[<0.813.0>, 1]`
- `task_execute_status` - status of the task execution operation,
  one of: `undefined`, `started`, `redirected`, `sticky_hit`, `sticky_miss`, `failed`
- `task_poll_status` - status of the task poll operation,
  one of: `undefined`, `null`, `task`, `error`
- `task_queue` - Temporal task queue name
- `worker_id` - task worker id `t:temporal_sdk_worker:id/0`
- `worker_type` - task worker type `t:temporal_sdk_worker:worker_type/0 | sticky_queue`

<hr>

### `[temporal_sdk, poller, poll, start]`

Emitted when the task poller enters the `poll` state and begins polling for a new task by sending a
long-poll gRPC request to the Temporal server.

<hr>

### `[temporal_sdk, poller, poll, stop]`

Emitted when a task poll request is successful and a task poll gRPC response is received.

<hr>

### `[temporal_sdk, poller, poll, exception]`

Emitted when a task poll request fails.

<hr>

### `[temporal_sdk, poller, execute, start]`

Emitted when the task poller enters `execute` state and starts task execution, after new task was
successfully polled from Temporal server.

<hr>

### `[temporal_sdk, poller, execute, stop]`

Emitted when a task execution operation is successful.

<hr>

### `[temporal_sdk, poller, execute, exception]`

Emitted when a task execution operation fails.

<hr>

### `[temporal_sdk, poller, wait, start]`

Emitted when the task poller enters the `wait` state after successfully executing task.

**Measurements**

- `limiter_delay` - leaky bucket rate limiter time delay length in milliseconds.

<hr>

### `[temporal_sdk, poller, wait, stop]`

Emitted when all rate limiter limit checks pass and the task poller is allowed to transition to the
`poll` state to poll for a new task.

**Measurements**

- `limited_by` - list of rate limiter [limitables](`t:temporal_sdk_limiter:limitable/0`) for which
  rate limits were exceeded, forcing the task poller state machine to remain idle in the `wait` state
  before polling next task execution from Temporal server.
  Expressed as a `map()`.
  Map key is a tuple of `t:temporal_sdk_limiter:level/0` and `t:temporal_sdk_limiter:limitable/0`.
  Map value is a time interval in milliseconds during which given limitable limits were exceeded.

Example measurements:

```erlang
#{duration => 101214764,limited_by => #{{worker,activity_regular} => 1000}}
```

## gRPC Client - `m:temporal_sdk_client`

### `[temporal_sdk, client, init]`

Emitted when the SDK gRPC client supervisor is initialized.

**Metadata**

- `cluster` - cluster name `t:temporal_sdk_cluster:cluster_name/0`
- `opts` - user-provided SDK gRPC client configuration options

<hr>

### `[temporal_sdk, client, start]`

Emitted when the SDK gRPC client supervisor has been successfully initialized and is started.

**Metadata**

- `cluster` - cluster name `t:temporal_sdk_cluster:cluster_name/0`
- `opts` - parsed SDK gRPC client configuration options

<hr>

### `[temporal_sdk, client, exception]`

Emitted when the SDK gRPC client supervisor fails to start.

**Metadata**

- `cluster` - cluster name `t:temporal_sdk_cluster:cluster_name/0`
- `opts` - user-provided SDK gRPC client configuration options
- `error` - reason for failure

## gRPC Request - `m:temporal_sdk_grpc`

### `[temporal_sdk, grpc, start]`

Emitted when a gRPC request starts.

**Metadata**

- `cluster` - cluster name `t:temporal_sdk_cluster:cluster_name/0`
- `request_name` - Temporal gRPC request service name `t:temporal_sdk_proto:service/0`

<hr>

### `[temporal_sdk, grpc, stop]`

Emitted when a gRPC request stops.

**Metadata**

- `cluster` - cluster name `t:temporal_sdk_cluster:cluster_name/0`
- `request_name` - Temporal gRPC request service name `t:temporal_sdk_proto:service/0`
- `endpoint` - the gRPC service endpoint that processed the given request,
  for example: `<<"127.0.0.1:7233">>`

<hr>

### `[temporal_sdk, grpc, exception]`

Emitted when a gRPC request fails.

**Metadata**

- `cluster` - cluster name `t:temporal_sdk_cluster:cluster_name/0`
- `request_name` - Temporal gRPC request service name `t:temporal_sdk_proto:service/0`
- `endpoint` - the gRPC service endpoint that processed the given request, set to `undefined` if
  endpoint is unknown
- `error` - reason for failure

## Task Counters - `m:temporal_sdk_limiter`

Events emitted by the fixed window rate limiter before the rate limiter task's frequency counter is reset.
Events are emitted at time intervals configured by the fixed window rate limiter `limiter_time_windows` option.

Measurements common to all `task_counter` events:

- `system_time`
- `interval` - the time window length for the fixed window rate limiter, configured via `limiter_time_windows`
- task counter measurement, where measurement key is a
  [Temporal limitable](`t:temporal_sdk_limiter:temporal_limitable/0`) and value is the count of tasks
  started within the specified `interval` time period

<hr>

### `[temporal_sdk, task_counter, node]`

Emitted by the SDK node-level fixed window rate limiter.

<hr>

### `[temporal_sdk, task_counter, cluster]`

Emitted by the SDK cluster-level fixed window rate limiter.

**Metadata**

- `cluster` - SDK cluster name `t:temporal_sdk_cluster:cluster_name/0`

<hr>

### `[temporal_sdk, task_counter, worker]`

Emitted by the task worker-level fixed window rate limiter.

**Metadata**

- `cluster` - SDK cluster name `t:temporal_sdk_cluster:cluster_name/0`
- `worker_id` - task worker id `t:temporal_sdk_worker:id/0`
- `worker_type` - task worker type `t:temporal_sdk_worker:worker_type/0`
