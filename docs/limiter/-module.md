Rate limiter module.

## OS Rate Limiter

OS rate limiting is controlled by OS resource usage reported by the
[`os_mon`](https://www.erlang.org/doc/apps/os_mon/api-reference.html) managed resource utilization
supervisors:

- `m:cpu_sup` - CPU load,
- `m:memsup` - memory utilization,
- `m:disksup` - mounted OS disks and partitions usage capacity.

`os_mon` OS monitoring OTP application is started by the SDK, however it is up to the user to provide
[`os_mon` configuration](https://www.erlang.org/doc/apps/os_mon/os_mon_app.html) as required.

OS rate limiter provides following OS limitables:

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

- `cpu1` average system load over the last minute retrieved from `cpu_sup:avg1/0`.
  Updated every minute.
  Set to `-1` if `m:cpu_sup` is not available.
  Requires `m:cpu_sup`.

- `cpu5` average system load over the last five minutes retrieved from `cpu_sup:avg5/0`.
  Updated every five minutes.
  Set to `-1` if `m:cpu_sup` is not available.
  Requires `m:cpu_sup`.

- `cpu15` average system load over the last 15 minutes retrieved from `cpu_sup:avg15/0`.
  Updated every 15 minutes.
  Set to `-1` if `m:cpu_sup` is not available.
  Requires `m:cpu_sup`.

- percentage of OS disk space or partition used as returned by the `disksup:get_disk_data/0` `Capacity` field.
  The key map is a tuple of `disk` and disk/partition ID, with the key value being the percentage of space used.
  Updated at time intervals retrieved from `disksup:get_check_interval/0`.
  Requires `m:disksup`.

Rate limiter OS limits are set with the `m:temporal_sdk_worker` `limits` configuration option.
OS limits can be retrieved and updated dynamically with:

- `temporal_sdk_worker:get_limiter_config/3`,
- `temporal_sdk_worker:set_limiter_config/4`,
- `temporal_sdk_worker:set_limiter_config/5`.

Example runtime SDK configuration OS limits settings for the workflow worker:

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

## Concurrency Rate Limiter

## Fixed Window Rate Limiter

## Task Poller Leaky Bucket Rate Limiter
