Returns a list of all known SDK telemetry events filtered by event prefix.

Example:

<!-- tabs-open -->
### Elixir

```elixir
iex(1)> :temporal_sdk_telemetry.events_by_prefix([[:temporal_sdk, :activity]])
[
  [:temporal_sdk, :activity, :executor, :start],
  [:temporal_sdk, :activity, :executor, :stop],
  [:temporal_sdk, :activity, :executor, :exception],
  [:temporal_sdk, :activity, :task, :start],
  [:temporal_sdk, :activity, :task, :stop],
  [:temporal_sdk, :activity, :task, :exception],
  [:temporal_sdk, :activity, :execution, :start],
  [:temporal_sdk, :activity, :execution, :stop],
  [:temporal_sdk, :activity, :execution, :exception]
]
```

### Erlang

```erlang
1> temporal_sdk_telemetry:events_by_prefix([[temporal_sdk, activity]]).
[[temporal_sdk,activity,executor,start],
 [temporal_sdk,activity,executor,stop],
 [temporal_sdk,activity,executor,exception],
 [temporal_sdk,activity,task,start],
 [temporal_sdk,activity,task,stop],
 [temporal_sdk,activity,task,exception],
 [temporal_sdk,activity,execution,start],
 [temporal_sdk,activity,execution,stop],
 [temporal_sdk,activity,execution,exception]]
```
<!-- tabs-close -->
