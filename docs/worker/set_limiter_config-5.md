Updates the dynamic configuration for the worker rate limiter on the Erlang nodes.

Function applies `set_limiter_config/4` on the Erlang nodes provided as a list using
`erpc:multicall/4`.
Returns `ok` if the multiple call configuration update operation was successful on all nodes.
Returns an `erpc:multicall/4` formatted error if the call operation fails on any of the nodes.

Successful example:
<!-- tabs-open -->
### Elixir

```elixir
iex(a@host)1> n = Node.list() ++ [Node.self()]
[:b@host, :a@host]
iex(a@host)2> TemporalSdk.Worker.set_limiter_config(:cluster_1, :activity, "worker", [{:limits, %{}}], n)
:ok
```

### Erlang

```erlang
(a@host)1> N = nodes() ++ [node()].
[b@host,a@host]
(a@host)2> temporal_sdk_worker:set_limiter_config(cluster_1, activity, "worker", #{limits => #{}}, N).
ok
```
<!-- tabs-close -->

Example with 3 nodes, where the first node update is successful, the second node does not have a
worker started, and the third node is not accessible:

<!-- tabs-open -->
### Elixir

```elixir
iex(a@host)1> n = [:b@host, :a@host, :c@host]
[:b@host, :a@host, :c@host]
iex(a@host)2> TemporalSdk.Worker.set_limiter_config(:cluster_1, :activity, "worker", [{:limits, %{}}], n)
[ok: :ok, ok: :invalid_worker, error: {:erpc, :noconnection}]
```

### Erlang

```erlang
(a@host)1> N = [b@host, a@host, c@host].
[b@host,a@host,c@host]
(a@host)3> temporal_sdk_worker:set_limiter_config(cluster_1, activity, "worker", #{limits => #{}}, N).
[{ok,ok},{ok,invalid_worker},{error,{erpc,noconnection}}]
```
<!-- tabs-close -->
