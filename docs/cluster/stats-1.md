Retrieves the current concurrency statistics from the SDK cluster-level concurrency rate limiter.

Function returns a `t:temporal_sdk_limiter:stats/0` map, where the map key is the
`t:temporal_sdk_limiter:temporal_limitable/0` and the value is the number of currently running limitable
task executions at the SDK cluster-level.
The number of task executions at the SDK cluster-level corresponds to the sum of task executions across
all runtime and dynamic task workers belonging to the given SDK cluster.

See also:

- `m:temporal_sdk_limiter#module-concurrency-and-fixed-window-rate-limiters`,
- `temporal_sdk_node:stats/0`,
- `temporal_sdk_worker:stats/3`.

Example:

<!-- tabs-open -->
### Elixir

```elixir
iex(1)> TemporalSdk.Cluster.stats(:cluster_1)
{:ok,
 %{
   workflow: 1,
   nexus: 0,
   activity_regular: 5,
   activity_session: 0,
   activity_eager: 0,
   activity_direct: 0
 }}
iex(2)> TemporalSdk.Cluster.stats(:invalid)
{:error, :invalid_cluster}
```

### Erlang

```erlang
1> temporal_sdk_cluster:stats(cluster_1).
{ok,#{activity_direct => 0,activity_eager => 0,
      activity_regular => 5,activity_session => 0,nexus => 0,
      workflow => 1}}
2> temporal_sdk_cluster:stats(invalid).
{error,invalid_cluster}
```
<!-- tabs-close -->
