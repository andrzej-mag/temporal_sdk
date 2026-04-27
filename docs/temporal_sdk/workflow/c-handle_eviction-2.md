Handles eviction of the workflow executor process.

[SDK Architecture - Workflow Eviction](architecture.md#workflow-eviction) section provides details
about workflow eviction mechanism.

The second function argument, `PollIdleTime`, represents the total time the workflow executor has
already spent waiting for a new task when polling the task queue and sticky queue, plus
the time spent executing this function.

The function is invoked at intervals determined by the worker options' workflow task `sticky_execution`
type setting:

- `local`: The long-poll timeout is determined by the `grpc_opts_longpoll` option (defined via
  `t:temporal_sdk_client:opts/0`) and the Temporal long-poll timeout, which defaults to 60
  seconds.
- `disabled` or `pool`: A fixed 60-second interval is used.

Function may return the following atoms:

- `ignore`  : Skips eviction.
- `evict`   : Evicts the workflow executor process.
- `default` : Uses the built-in default function implementation to determine whether the workflow
  should be evicted.

Function implementations should be non-blocking and free of side effects.
Function execution timeout is set to 50% of the workflow task timeout.

If callback function is not defined, default built-in implementation is used.
Default function implementation provides a smart eviction that depends on the following variables:

- Workflow history size in MB - `HistorySizeMB`,
- Workflow history events count - `EventsCount`,
- Executor idle time spent polling for new workflow tasks - `PollIdleTime`.

First, `BaseTimeSec` is calculated as a function of `HistorySizeMB`:

```
                             | if HistorySizeMB < 1: ignore
BaseTimeSec(HistorySizeMB) = | if HistorySizeMB > 40: 600
                             | else: -77 * HistorySizeMB + 3700
```

`TimeMultiplier` is calculated as a function of `EventsCount`:

```
                              | if EventsCount < 256: 1
TimeMultiplier(EventsCount) = | if EventsCount > 50_000: 3
                              | else: EventsCount / 25000 + 1
```

`EvictionTimeSec` is calculated using `BaseTimeSec` and `TimeMultiplier`:

```
EvictionTimeSec = round(BaseTimeSec * TimeMultiplier)
```

If calculated `EvictionTimeSec` is greater than `PollIdleTime` function returns `ignore` and eviction
is skipped, otherwise function returns `evict` and workflow is evicted.

Example calculation for workflow with history size 10MB and 1000 history events:

```
BaseTimeSec(10) = -77 * 10 + 3700 = 1390
TimeMultiplier(1000) = 1000 / 25000 + 1 = 1.04
EvictionTimeSec = round(1390 * 1.04) = 1446
```

Workflow will be evicted if `PollIdleTime` exceeds approximately 24 minutes.

[SDK Samples](https://github.com/andrzej-mag/temporal_sdk_samples)
[Workflow Eviction](https://github.com/andrzej-mag/temporal_sdk_samples/tree/main/docs/workflow_eviction.md)
sample demonstrates callback usage.
