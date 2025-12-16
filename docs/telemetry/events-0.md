Returns a list of all known SDK telemetry events.

Example:

<!-- tabs-open -->
### Elixir

```elixir
iex(1)> :temporal_sdk_telemetry.events()
[
  [:temporal_sdk, :node, :init],
  [:temporal_sdk, :node, :start],
  [:temporal_sdk, :node, :stats],
  [:temporal_sdk, :cluster, :init],
  [:temporal_sdk, :cluster, :start],
  [:temporal_sdk, :cluster, :exception],
  [:temporal_sdk, :cluster, :stats],
  [:temporal_sdk, :worker, :init],
  [:temporal_sdk, :worker, :start],
  [:temporal_sdk, :worker, :terminate],
  [:temporal_sdk, :worker, :exception],
  [:temporal_sdk, :worker, :stats],
  ...
]
```

### Erlang

```erlang
1> temporal_sdk_telemetry:events().
[[temporal_sdk,node,init],
 [temporal_sdk,node,start],
 [temporal_sdk,node,stats],
 [temporal_sdk,cluster,init],
 [temporal_sdk,cluster,start],
 [temporal_sdk,cluster,exception],
 [temporal_sdk,cluster,stats],
 [temporal_sdk,worker,init],
 [temporal_sdk,worker,start],
 [temporal_sdk,worker,terminate],
 [temporal_sdk,worker,exception],
 [temporal_sdk,worker,stats],
 ...
]
```
<!-- tabs-close -->
