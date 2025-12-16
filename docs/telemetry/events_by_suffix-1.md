Returns a list of all known SDK telemetry events filtered by event suffix.

Example:

<!-- tabs-open -->
### Elixir

```elixir
iex(1)> :temporal_sdk_telemetry.events_by_suffix([:exception])
[
  [:temporal_sdk, :cluster, :exception],
  [:temporal_sdk, :worker, :exception],
  [:temporal_sdk, :activity, :executor, :exception],
  [:temporal_sdk, :activity, :task, :exception],
  [:temporal_sdk, :activity, :execution, :exception],
  [:temporal_sdk, :nexus, :executor, :exception],
  [:temporal_sdk, :nexus, :task, :exception],
  [:temporal_sdk, :nexus, :execution, :exception],
  [:temporal_sdk, :workflow, :executor, :exception],
  [:temporal_sdk, :workflow, :task, :exception],
  [:temporal_sdk, :workflow, :execution, :exception],
  [:temporal_sdk, :client, :exception],
  [:temporal_sdk, :grpc, :exception],
  [:temporal_sdk, :poller, :poll, :exception],
  [:temporal_sdk, :poller, :execute, :exception]
]
```

### Erlang

```erlang
1> temporal_sdk_telemetry:events_by_suffix([exception]).
[[temporal_sdk,cluster,exception],
 [temporal_sdk,worker,exception],
 [temporal_sdk,activity,executor,exception],
 [temporal_sdk,activity,task,exception],
 [temporal_sdk,activity,execution,exception],
 [temporal_sdk,nexus,executor,exception],
 [temporal_sdk,nexus,task,exception],
 [temporal_sdk,nexus,execution,exception],
 [temporal_sdk,workflow,executor,exception],
 [temporal_sdk,workflow,task,exception],
 [temporal_sdk,workflow,execution,exception],
 [temporal_sdk,client,exception],
 [temporal_sdk,grpc,exception],
 [temporal_sdk,poller,poll,exception],
 [temporal_sdk,poller,execute,exception]]
```
<!-- tabs-close -->
