Rate limiter module.

## OS Rate Limiter

OS rate limiter controls task polling rates using OS resource usage reported by the
[`os_mon`](https://www.erlang.org/doc/apps/os_mon/api-reference.html) resource utilization supervisors:

- `m:memsup` - memory utilization,
- `m:cpu_sup` - CPU load,
- `m:disksup` - mounted OS disks and partitions usage capacity.

`os_mon` OS monitoring OTP application is started by the SDK, however it is up to the user to provide
[`os_mon` configuration](https://www.erlang.org/doc/apps/os_mon/os_mon_app.html) as required.

OS rate limiter manages following [OS limitables](`t:os_limitable/0`):

- `mem` - memory usage as a percentage calculated using code snippet below.
  Updated at time intervals retrieved from `memsup:get_check_interval/0`.
  Set to `-1` if `m:memsup` is not available.
  Requires `m:memsup`.

```erlang
case memsup:get_memory_data() of
    {0, 0, _} -> -1;
    {Total, Allocated, _Worst} -> round(Allocated / Total * 100)
end;
```

- `cpu1` - average system load over the last minute retrieved from `cpu_sup:avg1/0`.
  Updated every minute.
  Set to `-1` if `m:cpu_sup` is not available.
  Requires `m:cpu_sup`.

- `cpu5` - average system load over the last five minutes retrieved from `cpu_sup:avg5/0`.
  Updated every five minutes.
  Set to `-1` if `m:cpu_sup` is not available.
  Requires `m:cpu_sup`.

- `cpu15` - average system load over the last 15 minutes retrieved from `cpu_sup:avg15/0`.
  Updated every 15 minutes.
  Set to `-1` if `m:cpu_sup` is not available.
  Requires `m:cpu_sup`.

- `{disk, Id}` - percentage of OS disk space or partition used as returned by the
  `disksup:get_disk_data/0` `Capacity` field. The key is a tuple of `disk` and disk/partition Id,
  with the key value being the percentage of space used.
  Updated at time intervals retrieved from `disksup:get_check_interval/0`.
  Requires `m:disksup`.

Values retrieved from the `os_mon` resource utilization supervisors are stored by the SDK using
`m:counters`, which provides practically unlimited rate limiter performance while requiring negligible
resources.

Rate limiter OS limits are set with the `m:temporal_sdk_worker` `limits` configuration option.
OS limits can be retrieved and updated dynamically with:

- `temporal_sdk_worker:get_limiter_config/3`,
- `temporal_sdk_worker:set_limiter_config/4`,
- `temporal_sdk_worker:set_limiter_config/5`.

Example runtime SDK configuration OS limits settings for "worker_1" workflow worker:

<!-- tabs-open -->
### Elixir

```elixir
config :temporal_sdk,
  clusters: [
    cluster_1: [
      activities: [%{:task_queue => "default"}],
      workflows: [
        [
          worker_id: :worker_1,
          task_queue: "worker_1_tq",
          limits: %{
            :os => %{
              :mem => 90,
              :cpu1 => 500,
              :cpu5 => 500,
              :cpu15 => 500,
              {:disk, ~c"/"} => 80,
              {:disk, ~c"/tmp"} => 90
            }
          }
        ]
      ]
    ]
  ]
```

### Erlang

```erlang
{temporal_sdk, [
    {clusters, [
        {cluster_1, [
            {activities, [#{task_queue => "default"}]},
            {workflows, [
                [
                    {worker_id, worker_1},
                    {task_queue, "worker_1_tq"},
                    {limits, #{
                        os =>
                            #{
                                mem => 90,
                                cpu1 => 500,
                                cpu5 => 500,
                                cpu15 => 500,
                                {disk, "/"} => 80,
                                {disk, "/tmp"} => 90
                            }
                    }}
                ]
            ]}
        ]}
    ]}
]}
```
<!-- tabs-close -->

## Concurrency and Fixed Window Rate Limiters

Concurrency and fixed window rate limiters control task polling rates using task execution counters.
Task execution counters are implemented with `m:counters`, which provides practically unlimited
rate limiter performance while requiring negligible resources.

Concurrency rate limiter counters are incremented by task executors when task execution begins.
Concurrency rate limiter counters are decremented by task executors when task execution terminates.
Fixed window rate limiter counters are incremented by task executors when task execution begins.
Fixed window rate limiter counters are periodically reset at time intervals configured by the
`limiter_time_windows` configuration option.

Concurrency and fixed window rate limiters are available at SDK node, SDK cluster and task worker
levels.
Counters at the SDK node-level correspond to the sum of the respective counters at the SDK cluster-level.
Counters at the SDK cluster-level correspond to the sum of the respective counters from the task
workers that belong to the given SDK cluster.

Concurrency rate limiters do not have any configuration options.
Fixed window rate limiter time windows are configured using the `limiter_time_windows` configuration
option at each limiting level.

Example configuration setting SDK node-level fixed window rate limiter time windows to 10 minutes:

<!-- tabs-open -->
### Elixir

```elixir
config :temporal_sdk,
  node: [
    limiter_time_windows: [
      activity_direct: {10, :minute},
      activity_eager: {10, :minute},
      activity_regular: {10, :minute},
      activity_session: {10, :minute},
      nexus: {10, :minute},
      workflow: {10, :minute}
    ]
  ]
```

### Erlang

```erlang
{temporal_sdk, [
    {node, [
        {limiter_time_windows, [
            {activity_direct, {10, minute}},
            {activity_eager, {10, minute}},
            {activity_regular, {10, minute}},
            {activity_session, {10, minute}},
            {nexus, {10, minute}},
            {workflow, {10, minute}}
        ]}
    ]}
]}
```
<!-- tabs-close -->

Concurrency and fixed window rate limiters limits are set with the `limits` `t:temporal_sdk_worker:opts/0`
task worker configuration option. Limits can be applied at the SDK node, cluster, and worker rate
limiting levels.
At the worker level, only a subset of limitables corresponding to the given worker type can be used.
Concurrency and fixed window rate limiters limits can be retrieved and updated dynamically with:

- `temporal_sdk_worker:get_limiter_config/3`,
- `temporal_sdk_worker:set_limiter_config/4`,
- `temporal_sdk_worker:set_limiter_config/5`.

Example runtime SDK configuration limits settings for "worker_1" workflow worker:

<!-- tabs-open -->
### Elixir

```elixir
config :temporal_sdk,
  clusters: [
    cluster_1: [
      activities: [%{:task_queue => "default"}],
      workflows: [
        [
          worker_id: :worker_1,
          task_queue: "worker_1_tq",
          limits: [
            node: [
              activity_direct: {200, 1_000},
              activity_eager: {200, 1_000},
              activity_regular: {200, 1_000},
              activity_session: {200, 1_000},
              nexus: {200, 1_000},
              workflow: {200, 1_000}
            ],
            cluster: [
              activity_direct: {10, 100},
              activity_eager: {10, 100},
              activity_regular: {10, 100},
              activity_session: {10, 100},
              nexus: {10, 100},
              workflow: {10, 100}
            ],
            worker: [
              workflow: {5, 50}
            ]
          ]
        ]
      ]
    ]
  ]
```

### Erlang

```erlang
{temporal_sdk, [
    {clusters, [
        {cluster_1, [
            {activities, [#{task_queue => "default"}]},
            {workflows, [
                [
                    {worker_id, worker_1},
                    {task_queue, "worker_1_tq"},
                    {limits, [
                        {node, [
                            {activity_direct, {200, 1_000}},
                            {activity_eager, {200, 1_000}},
                            {activity_regular, {200, 1_000}},
                            {activity_session, {200, 1_000}},
                            {nexus, {200, 1_000}},
                            {workflow, {200, 1_000}}
                        ]},
                        {cluster, [
                            {activity_direct, {10, 100}},
                            {activity_eager, {10, 100}},
                            {activity_regular, {10, 100}},
                            {activity_session, {10, 100}},
                            {nexus, {10, 100}},
                            {workflow, {10, 100}}
                        ]},
                        {worker, [
                            {workflow, {5, 50}}
                        ]}
                    ]}
                ]
            ]}
        ]}
    ]}
]}
```
<!-- tabs-close -->

In the example above, the polling rate of workflow tasks polled from the "worker_1_tq" task queue
will be limited if:

- The number of concurrently running tasks at the SDK node-level exceeds 200 for any of the following:
  activity_direct, activity_eager, activity_regular, activity_session, nexus, or workflow.
- The number of fixed window rate limited tasks at the SDK node-level exceeds 1000 for any of the following:
  activity_direct, activity_eager, activity_regular, activity_session, nexus, or workflow.

- The number of concurrently running tasks at the SDK cluster-level exceeds 10 for any of the following:
  activity_direct, activity_eager, activity_regular, activity_session, nexus, or workflow.
- The number of fixed window rate limited tasks at the SDK cluster-level exceeds 100 for any of the following:
  activity_direct, activity_eager, activity_regular, activity_session, nexus, or workflow.

- The number of concurrently running workflow tasks spawned by the "worker_1" worker exceeds 5,
- The number of fixed window rate limiter workflow tasks spawned by the "worker_1" worker exceeds 50.

## Task Poller Leaky Bucket Rate Limiter
