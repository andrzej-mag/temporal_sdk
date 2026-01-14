Retrieves the current concurrency statistics from the SDK node-level concurrency rate limiter.

Function returns a `t:temporal_sdk_limiter:stats/0` map, where the map key is the
`t:temporal_sdk_limiter:temporal_limitable/0` and the value is the number of currently running limitable
task executions at the SDK node-level.
The number of task executions at the SDK node-level corresponds to the sum of task executions across
all SDK clusters.
A limitable here refers to a Temporal task, such as a Temporal activity, nexus, or workflow task,
that is capable of rate limiting the polling rate of Temporal tasks.
See `m:temporal_sdk_limiter#module-concurrency-and-fixed-window-rate-limiters` for more details.

## Example

<!-- tabs-open -->
### Elixir

```elixir
iex(1)> TemporalSdk.Node.stats()
%{
  nexus: 0,
  workflow: 5,
  activity_regular: 10,
  activity_session: 0,
  activity_eager: 0,
  activity_direct: 0
}
```

### Erlang

```erlang
1> temporal_sdk_node:stats().
#{activity_direct => 0,activity_eager => 0,
  activity_regular => 10,activity_session => 0,nexus => 0,
  workflow => 5}
```
<!-- tabs-close -->
