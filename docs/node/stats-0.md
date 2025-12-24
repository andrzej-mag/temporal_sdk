Retrieves the current SDK node limitables concurrency statistics from the SDK concurrency rate limiter.

Function returns a `t:temporal_sdk_limiter:stats/0` map, where the map key is the
`t:temporal_sdk_limiter:temporal_limitable/0` and the value is the number of currently running limitable
task executions on the SDK node rate limiter level.

A limitable is a rate-limited Temporal awaitable task, such as a Temporal activity, nexus, or workflow
task execution. See `m:temporal_sdk_limiter` for more details.

## Example

<!-- tabs-open -->
### Elixir

```elixir
iex(1)> :temporal_sdk_node.stats()
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
