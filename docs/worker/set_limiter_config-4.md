Updates the dynamic configuration of the rate limiter.

Default values for the `limits` limiter levels are set to `#{}`, which means that setting
`limits` to `#{}` will reset all rate limiter concurrency and fixed window limits.

Task worker will not start new tasks until the new rate limiter limits, defined in the updated limiter
configuration, are satisfied.
For example, if the number of currently ongoing task executions exceeds the concurrency limits set by
the new rate limiter configuration, new tasks will not be started until the overflow task executions
are drained to meet the new limits.

[SDK Samples](https://github.com/andrzej-mag/temporal_sdk_samples)
[Rate Limiter](https://hexdocs.pm/temporal_sdk_samples/rate_limiter.html)
example demonstrates function use.

Example:
<!-- tabs-open -->
### Elixir

```elixir
iex(1)> TemporalSdk.Worker.start(:cluster_1, :activity, worker_id: "test_worker",
        task_queue: "test_tq", task_poller_pool_size: 1,
        limits: %{:worker => %{:activity_regular => {10, 600}}})
{:ok,
 %{
   task_queue: "test_tq",
   temporal_name_to_erlang: &:temporal_sdk_api.temporal_name_to_erlang/2,
   namespace: ~c"default",
   worker_version: %{},
   task_settings: %{
     data: :undefined,
     last_heartbeat: [:undefined],
     start_to_close_timeout_ratio: 0.8,
     schedule_to_close_timeout_ratio: 0.8,
     heartbeat_timeout_ratio: 0.8
   },
   worker_id: "test_worker",
   allowed_temporal_names: :all,
   allowed_erlang_modules: :all,
   limiter_time_windows: %{activity_regular: 60000},
   telemetry_poll_interval: 10000,
   limits: %{
     node: %{},
     os: %{},
     worker: %{activity_regular: {10, 600}},
     cluster: %{}
   },
   task_poller_pool_size: 1,
   task_poller_limiter: %{limit: :infinity, time_window: :undefined},
   limiter_check_frequency: 500
 }}
iex(2)> TemporalSdk.Worker.set_limiter_config(:cluster_1, :activity, "test_worker",
        limits: %{:worker => %{:activity_regular => {1, 60}}},
        task_poller_limiter: %{:limit => 60, :time_window => {1, :minute}})
:ok
iex(3)> TemporalSdk.Worker.get_limiter_config(:cluster_1, :activity, "test_worker")
{:ok,
 %{
   limits: %{
     node: %{},
     os: %{},
     worker: %{activity_regular: {1, 60}},
     cluster: %{}
   },
   task_poller_limiter: %{limit: 60, time_window: {1, :minute}},
   limiter_check_frequency: 500
 }}
iex(4)> TemporalSdk.Worker.set_limiter_config(:cluster_1, :activity, "test_worker",
        limits: %{})
:ok
iex(5)> TemporalSdk.Worker.get_limiter_config(:cluster_1, :activity, "test_worker")
{:ok,
 %{
   limits: %{node: %{}, os: %{}, worker: %{}, cluster: %{}},
   task_poller_limiter: %{limit: 60, time_window: {1, :minute}},
   limiter_check_frequency: 500
 }}
```

### Erlang

```erlang
1> temporal_sdk_worker:start(cluster_1, activity, [{worker_id, "test_worker"},
   {task_queue, "test_tq"}, {task_poller_pool_size, 1},
   {limits, #{worker => #{activity_regular => {10, 600}}}}]).
{ok,#{namespace => "default",worker_id => "test_worker",
      task_queue => "test_tq",
      task_settings =>
          #{data => undefined,
            last_heartbeat => [undefined],
            heartbeat_timeout_ratio => 0.8,
            schedule_to_close_timeout_ratio => 0.8,
            start_to_close_timeout_ratio => 0.8},
      worker_version => #{},allowed_temporal_names => all,
      allowed_erlang_modules => all,
      temporal_name_to_erlang =>
          fun temporal_sdk_api:temporal_name_to_erlang/2,
      task_poller_pool_size => 1,
      task_poller_limiter =>
          #{limit => infinity,time_window => undefined},
      limits =>
          #{node => #{},os => #{},
            worker => #{activity_regular => {10,600}},
            cluster => #{}},
      limiter_check_frequency => 500,
      limiter_time_windows => #{activity_regular => 60000},
      telemetry_poll_interval => 10000}}
2> temporal_sdk_worker:set_limiter_config(cluster_1, activity, "test_worker",
   [{limits, #{worker => #{activity_regular => {1, 60}}}},
   {task_poller_limiter, #{limit => 60, time_window => {1, minute}}}]).
ok
3> temporal_sdk_worker:get_limiter_config(cluster_1, activity, "test_worker").
{ok,#{task_poller_limiter =>
          #{limit => 60,time_window => {1,minute}},
      limits =>
          #{node => #{},os => #{},
            worker => #{activity_regular => {1,60}},
            cluster => #{}},
      limiter_check_frequency => 500}}
4> temporal_sdk_worker:set_limiter_config(cluster_1, activity, "test_worker", [{limits, #{}}]).
ok
5> temporal_sdk_worker:get_limiter_config(cluster_1, activity, "test_worker").
{ok,#{task_poller_limiter =>
          #{limit => 60,time_window => {1,minute}},
      limits =>
          #{node => #{},os => #{},worker => #{},cluster => #{}},
      limiter_check_frequency => 500}}
```
<!-- tabs-close -->
