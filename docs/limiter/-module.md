Rate limiter module.

SDK provides the following rate limiters:

- [OS rate limiter](#module-os-rate-limiter),
- [concurrency and fixed window rate limiters](#module-concurrency-and-fixed-window-rate-limiters),
- [task worker task poller leaky bucket rate
limiter](#module-task-poller-leaky-bucket-rate-limiter).

OS rate limiting is controlled by OS resource usage, including memory, CPU load, and disk capacity.
Concurrency and fixed window rate limiting are controlled by the Temporal task execution counters.
Leaky bucket rate limiting is controlled by task poll leak rates derived from user-provided configuration.

Rate limiter limits are checked and enforced during the following operations:

- starting an eager workflow execution using `temporal_sdk:start_workflow/3` or
  `temporal_sdk:start_workflow/4` with the `request_eager_execution` option set,
- polling for a new task execution from the Temporal server by the task worker's task poller.

Rate limiters can be used individually or in combination. When using concurrency and fixed window
rate limiters in combination with a leaky bucket rate limiter, special attention is required as the
functionality of these limiters may overlap.

See also:

- [SDK Architecture - Rate Limiting](architecture.md#rate-limiting),
- [SDK Samples repository](https://github.com/andrzej-mag/temporal_sdk_samples) rate limiter examples
for [Elixir](https://hexdocs.pm/temporal_sdk_samples/RateLimiter.html) and
[Erlang](https://hexdocs.pm/temporal_sdk_samples/rate_limiter.html).

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

Values retrieved from the `os_mon` resource utilization supervisors are stored by the SDK using OTP
`m:counters`.

OS rate limiter limits are set with the `t:temporal_sdk_worker:opts/0`
`limits` task worker configuration option.

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

Concurrency and fixed window rate limiters control task polling rates using task execution
concurrency and frequency counters.
Task execution counters are implemented using OTP `m:counters`.

Concurrency and fixed window frequency counters are incremented by task executors when task execution
begins.
Concurrency counters are decremented by task executors when task execution terminates.
Fixed window frequency counters are periodically reset at time intervals configured by the
`limiter_time_windows` configuration option.

Concurrency and fixed window rate limiters are available at SDK node, SDK cluster and task worker
levels.
Counters at the SDK node-level correspond to the sum of the respective counters at the SDK cluster-level.
Counters at the SDK cluster-level correspond to the sum of the respective counters from the task
workers that belong to the given SDK cluster.

Fixed window rate limiter task counters are used to emit
[`[temporal_sdk, task_counter]`](`m:temporal_sdk_telemetry#module-task-counters-m-temporal_sdk_limiter`)
telemetry events at time intervals configured by the `limiter_time_windows` option.

Concurrency rate limiters do not have any configuration options.
Fixed window rate limiter time windows are configured using the `limiter_time_windows` configuration
option at each SDK limiting level: node, cluster, and worker.

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

Concurrency and fixed window rate limiters limits are set with the `t:temporal_sdk_worker:opts/0`
`limits` task worker configuration option.
Limits can be applied at the SDK node, cluster, and worker rate limiting levels.
At the worker level, only limitables that are specific to the given worker type are permitted.

[Limits values](`t:temporal_sdk_limiter:limit/0`) are set as tuples where the first element is a
concurrency limit and the second element is a fixed window frequency limit.

Example runtime SDK configuration concurrency and frequency limits settings for "worker_1" workflow
worker:

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
          task_poller_pool_size: 1,
          limits: [
            node: [
              activity_regular: {200, 1_000},
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
                    {task_poller_pool_size, 1},
                    {limits, [
                        {node, [
                            {activity_regular, {200, 1_000}},
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

In the example above, the polling rate of workflow tasks polled by "worker_1" from the "worker_1_tq"
task queue will be limited if:

- The number of concurrently running tasks at the SDK node-level exceeds 200 for any of the following:
  activity_regular, nexus, or workflow.
- The number of fixed window rate limited tasks at the SDK node-level exceeds 1000 for any of the following:
  activity_regular, nexus, or workflow.

- The number of concurrently running tasks at the SDK cluster-level exceeds 10 for any of the following:
  activity_direct, activity_eager, activity_regular, activity_session, nexus, or workflow.
- The number of fixed window rate limited tasks at the SDK cluster-level exceeds 100 for any of the following:
  activity_direct, activity_eager, activity_regular, activity_session, nexus, or workflow.

- The number of concurrently running workflow tasks spawned by the "worker_1" worker exceeds 5,
- The fixed window frequency of workflow tasks spawned by the "worker_1" worker exceeds 50.

Notice that "worker_1" has a `task_poller_pool_size` of 1 in the example above.
The "worker_1" workflow worker limits the maximum number of concurrently running workflow task
executions to 5, so a single workflow task poller will be sufficient.
See also [SDK Architecture - Rate Limiting](architecture.md#rate-limiting).

## Task Poller Leaky Bucket Rate Limiter

Leaky bucket rate limiter controls task polling rate using leak time intervals derived from
`t:temporal_sdk_worker:task_poller_limiter/0` data.

Conventional leaky bucket implementation assumes that the bucket is intermittently filled with incoming
requests, which leak at a constant rate.
In our case, we can assume an infinite capacity bucket that is continuously filled without overflow
with task poll requests and leaks at a constant rate.

Leaky bucket rate limiting is implemented within the task worker task poller state machine.
`t:temporal_sdk_worker:task_poller_limiter/0` defines two rate limiter parameters: `Limit` and `TimeWindow`.
The minimum time interval between task poll gRPC requests executed by the task poller is calculated as:
`TimeWindowMsec / Limit`.
The wait time between task polls is implemented using `m:gen_statem` timeouts, which have a time
resolution of 1 millisecond.
This constraint limits the leak time interval to values greater than or equal to 1 millisecond per
poll request.
This corresponds to a rate limiter that limits the task poll rate to <1000 task poll requests per
second or provides unrestricted task poll rate.

Leaky bucket rate limiting is configured with the `t:temporal_sdk_worker:opts/0` `task_poller_limiter`
task worker configuration option.
`task_poller_limiter` is set per individual task poller. The total task worker polling capacity equals
the number of task pollers specified by `task_poller_pool_size` multiplied by the individual poller
capacity set with `task_poller_limiter` option.

Example runtime SDK configuration leaky bucket settings for "worker_1" workflow worker:

<!-- tabs-open -->
### Elixir

```elixir
config :temporal_sdk,
  clusters: [
    cluster_1: [
      activities: [[task_queue: "default"]],
      workflows: [
        [
          worker_id: :worker_1,
          task_queue: "worker_1_tq",
          task_poller_pool_size: 2,
          task_poller_limiter: %{:limit => 10, :time_window => {1, :minute}}
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
            {activities, [[{task_queue, "default"}]]},
            {workflows, [
                [
                    {worker_id, worker_1},
                    {task_queue, "worker_1_tq"},
                    {task_poller_pool_size, 2},
                    {task_poller_limiter, #{limit => 10, time_window => {1, minute}}}
                ]
            ]}
        ]}
    ]}
]}
```
<!-- tabs-close -->

In the example above, the single task poller is limited to 10 requests per minute, which means that
the minimum time interval between poll requests will be 6 seconds.
As poller pool size is set to 2, total workflow worker task poll rate will be equal to 20 requests
per minute or one task poll request per 3 seconds.

## Rate Limiter Dynamic Configuration

Following rate limiter [configuration options](`t:temporal_sdk_worker:limiter_config/0`) can be
updated dynamically:

- `limits`,
- `task_poller_limiter`,
- `limiter_check_frequency`.

Following functions can be used to retrieve and update rate limiter dynamic configuration:

- `temporal_sdk_worker:get_limiter_config/3`,
- `temporal_sdk_worker:set_limiter_config/4`,
- `temporal_sdk_worker:set_limiter_config/5`,
- Elixir counterparts of above in the `TemporalSdk.Worker` module.
