Returns true if the given cluster is started, `{error, invalid_cluster}` error otherwise.

Example:

<!-- tabs-open -->
### Elixir

```elixir
iex(1)> TemporalSdk.Cluster.is_started(:cluster_1)
true
iex(2)> TemporalSdk.Cluster.is_started(:invalid)
{:error, :invalid_cluster}
```

### Erlang

```erlang
1> temporal_sdk_cluster:is_started(cluster_1).
true
2> temporal_sdk_cluster:is_started(invalid).
{error,invalid_cluster}
```
<!-- tabs-close -->
