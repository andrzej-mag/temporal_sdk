SDK telemetry helpers module.

## SDK Node - `m:temporal_sdk_node`

### `[temporal_sdk, node, init]`

Emitted when the SDK node supervisor is initialized.

**Metadata**

- `opts` - `node` SDK configuration options as provided by the user

**Measurements**

- `system_time` - `erlang:system_time()`

<hr>
### `[temporal_sdk, node, start]`

Emitted when the SDK node supervisor is started.

**Metadata**

- `opts` - parsed `node` SDK configuration options

**Measurements**

- `system_time` - `erlang:system_time()`

<hr>
### `[temporal_sdk, node, stats]`

SDK node stats emitted every `telemetry_poll_interval` time interval.

**Metadata**

**Measurements**

- `clusters_count` - equal to `length(temporal_sdk_cluster:list())`
- `clusters_list` - equal to `temporal_sdk_cluster:list()`
- `stats` - equal to `temporal_sdk_node:stats()`
- `os_stats` - equal to `temporal_sdk_node:os_stats()`

## Temporal Cluster - `m:temporal_sdk_cluster`

- [temporal_sdk, cluster, init]
- [temporal_sdk, cluster, start]
- [temporal_sdk, cluster, exception]
- [temporal_sdk, cluster, stats]

## Worker - `m:temporal_sdk_worker`

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

## gRPC Client - `m:temporal_sdk_client`

- [temporal_sdk, client, start]
- [temporal_sdk, client, stop]
- [temporal_sdk, client, exception]

## gRPC Request - `m:temporal_sdk_grpc`

- [temporal_sdk, grpc, start]
- [temporal_sdk, grpc, stop]
- [temporal_sdk, grpc, exception]

## Task Poller - `temporal_sdk_poller`

- [temporal_sdk, poller, poll, start]
- [temporal_sdk, poller, poll, stop]
- [temporal_sdk, poller, poll, exception]
- [temporal_sdk, poller, execute, start]
- [temporal_sdk, poller, execute, stop]
- [temporal_sdk, poller, execute, exception]
- [temporal_sdk, poller, wait, start]
- [temporal_sdk, poller, wait, stop]
