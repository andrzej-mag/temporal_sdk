Returns the current dynamic configuration of the rate limiter.

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
   worker_id: "test_worker",
   task_poller_pool_size: 1,
   limits: %{
     node: %{},
     os: %{},
     worker: %{activity_regular: {10, 600}},
     cluster: %{}
   },
   task_poller_limiter: %{limit: :infinity, time_window: :undefined},
   limiter_check_frequency: 500,
   task_settings: %{
     data: :undefined,
     last_heartbeat: [:undefined],
     heartbeat_timeout_ratio: 0.8,
     schedule_to_close_timeout_ratio: 0.8,
     start_to_close_timeout_ratio: 0.8
   },
   namespace: ~c"default",
   telemetry_poll_interval: 10000,
   limiter_time_windows: %{activity_regular: 60000},
   worker_version: %{},
   temporal_name_to_erlang: &:temporal_sdk_api.temporal_name_to_erlang/2,
   allowed_erlang_modules: :all,
   allowed_temporal_names: :all
 }}
iex(2)> TemporalSdk.Worker.get_limiter_config(:cluster_1, :activity, "test_worker")
{:ok,
 %{
   limits: %{
     node: %{},
     os: %{},
     worker: %{activity_regular: {10, 600}},
     cluster: %{}
   },
   task_poller_limiter: %{limit: :infinity, time_window: :undefined},
   limiter_check_frequency: 500
 }}
```

### Erlang

```erlang
1> temporal_sdk_worker:start(cluster_1, activity, [{worker_id, "test_worker"},
   {task_queue, "test_tq"}, {task_poller_pool_size, 1},
   {limits, #{worker => #{activity_regular => {10, 600}}}}]).
{ok,#{namespace => "default",task_queue => "test_tq",
      telemetry_poll_interval => 10000,
      limiter_time_windows => #{activity_regular => 60000},
      worker_version => #{},worker_id => "test_worker",
      task_settings =>
          #{data => undefined,
            last_heartbeat => [undefined],
            heartbeat_timeout_ratio => 0.8,
            schedule_to_close_timeout_ratio => 0.8,
            start_to_close_timeout_ratio => 0.8},
      limits =>
          #{node => #{},os => #{},
            worker => #{activity_regular => {10,600}},
            cluster => #{}},
      task_poller_limiter =>
          #{limit => infinity,time_window => undefined},
      task_poller_pool_size => 1,limiter_check_frequency => 500,
      temporal_name_to_erlang =>
          fun temporal_sdk_api:temporal_name_to_erlang/2,
      allowed_erlang_modules => all,
      allowed_temporal_names => all}}
2> temporal_sdk_worker:get_limiter_config(cluster_1, activity, "test_worker").
{ok,#{limits =>
          #{node => #{},os => #{},
            worker => #{activity_regular => {10,600}},
            cluster => #{}},
      task_poller_limiter =>
          #{limit => infinity,time_window => undefined},
      limiter_check_frequency => 500}}
```
<!-- tabs-close -->
