# SDK Architecture

```mermaid
flowchart TD
  Node@{ shape: rect, label: "SDK node"}
  NodeTool@{ shape: lin-rect, label: "scope <br> stats telemetry <br> node rate limiter <br> OS rate limiter"}

  Cluster1@{ shape: rect, label: "SDK cluster 1"}
  ClusterN@{ shape: rect, label: "SDK cluster N"}
  ClusterTool@{ shape: lin-rect, label: "gRPC client <br> stats telemetry <br> cluster rate limiter"}
  ClusterToolN@{ shape: lin-rect, label: "gRPC client <br> stats telemetry <br> cluster rate limiter"}

  Activity@{ shape: processes, label: "Activity worker" }
  ActivityTool@{ shape: lin-rect, label: "task poller <br> poller rate limiter <br> stats telemetry <br> worker  rate limiter" }

  Nexus@{ shape: processes, label: "Nexus worker" }
  NexusTool@{ shape: lin-rect, label: "task poller <br> poller rate limiter <br> stats telemetry <br> worker  rate limiter" }

  Workflow@{ shape: processes, label: "Workflow worker" }
  WorkflowTool@{ shape: lin-rect, label: "task poller <br> poller rate limiter <br> stats telemetry <br> worker  rate limiter" }

  Task@{ shape: processes, label: "A/N/W task worker" }
  TaskTool@{ shape: lin-rect, label: "task poller <br> poller rate limiter <br> stats telemetry <br> worker rate limiter" }

  ActivityExec@{ shape: processes, label: "Activity executor" }
  NexusExec@{ shape: processes, label: "Nexus executor" }
  WorkflowExec@{ shape: processes, label: "Workflow executor" }
  TaskExec@{ shape: processes, label: "A/N/W task executor" }

  TemporalService1@{ shape: processes, label: "Temporal Service 1 <br> Temporal Server(s)"}
  TemporalServiceN@{ shape: processes, label: "Temporal Service N <br> Temporal Server(s)"}

  style TemporalService1 stroke-dasharray: 3 3
  style TemporalServiceN stroke-dasharray: 3 3

  Node --> Cluster1
  Cluster1 <-.gRPC.....-> TemporalService1
  Cluster1 --> ClusterTool
  Cluster1 ---> Activity
  Cluster1 ---> Nexus
  Cluster1 ---> Workflow
  Node --> NodeTool
  Node --> ClusterN
  ClusterN <-.gRPC.....-> TemporalServiceN
  ClusterN --> ClusterToolN
  ClusterN ---> Task
  Activity --> ActivityTool
  Activity -..-> ActivityExec
  Nexus --> NexusTool
  Nexus -..-> NexusExec
  Workflow --> WorkflowTool
  Workflow -..-> WorkflowExec
  Task --> TaskTool
  Task -..-> TaskExec

  click Node "https://hexdocs.pm/temporal_sdk/temporal_sdk_node.html" _blank
  click NodeTool "https://hexdocs.pm/temporal_sdk/temporal_sdk_node.html" _blank

  click Cluster1 "https://hexdocs.pm/temporal_sdk/temporal_sdk_cluster.html" _blank
  click ClusterN "https://hexdocs.pm/temporal_sdk/temporal_sdk_cluster.html" _blank
  click ClusterTool "https://hexdocs.pm/temporal_sdk/temporal_sdk_cluster.html" _blank
  click ClusterToolN "https://hexdocs.pm/temporal_sdk/temporal_sdk_cluster.html" _blank

  click Activity "https://hexdocs.pm/temporal_sdk/temporal_sdk_worker.html" _blank
  click ActivityTool "https://hexdocs.pm/temporal_sdk/temporal_sdk_worker.html" _blank
  click Nexus "https://hexdocs.pm/temporal_sdk/temporal_sdk_worker.html" _blank
  click NexusTool "https://hexdocs.pm/temporal_sdk/temporal_sdk_worker.html" _blank
  click Workflow "https://hexdocs.pm/temporal_sdk/temporal_sdk_worker.html" _blank
  click WorkflowTool "https://hexdocs.pm/temporal_sdk/temporal_sdk_worker.html" _blank
  click Task "https://hexdocs.pm/temporal_sdk/temporal_sdk_worker.html" _blank
  click TaskTool "https://hexdocs.pm/temporal_sdk/temporal_sdk_worker.html" _blank

  click ActivityExec "https://hexdocs.pm/temporal_sdk/temporal_sdk_activity.html" _blank
  click NexusExec "https://hexdocs.pm/temporal_sdk/temporal_sdk_nexus.html" _blank
  click WorkflowExec "https://hexdocs.pm/temporal_sdk/temporal_sdk_workflow.html" _blank

  click TemporalService1 "https://docs.temporal.io/temporal-service" _blank
  click TemporalServiceN "https://docs.temporal.io/temporal-service" _blank
```

## Workflow Execution

After workflow execution is started by calling `TemporalSdk.start_workflow/3` or
`:temporal_sdk.start_workflow/3`, the given SDK cluster's client sends a `StartWorkflowExecutionRequest`
gRPC request to the Temporal service Temporal server.
The Temporal server schedules the new workflow task execution on a user-defined workflow task queue.
The workflow task execution is then polled from the Temporal server by the SDK workflow task worker
polling given workflow task queue.
Workflow task workers typically run across multiple worker hosts within the user's cluster.
After a new workflow task execution is polled, the SDK is responsible for processing the polled
workflow task execution using workflow task executor.
The Temporal server may dispatch the given workflow task execution to one or more user cluster hosts
running workflow task workers.

### Single Workflow Execution and Workflow Scope

Majority of other Temporal SDK implementations use the concept of
["Worker Task Slots"](https://docs.temporal.io/develop/worker-performance#slots) when processing task
executions.
After a new task execution is polled from a task queue and task slot is reserved by the SDK, task
execution is cached and executed on each host that polled for the new task.
If the Temporal server dispatches duplicate task executions to multiple worker hosts in the user cluster,
other Temporal SDK implementations will cache and execute the polled task on each involved worker host
using the worker task slots mechanism.
Each duplicate workflow task execution repeats the same work, replaying the identical event history and
competing with other executions to reach completion. This approach can lead to redundant task data storage
and repeated execution of the same task code across multiple worker hosts.

Erlang SDK utilizes Erlang OTP distribution to optimize Temporal workflow task execution.
If `t::temporal_sdk_node.opts/0` `enable_single_distributed_workflow_execution` configuration option
is set to true (default and recommended value), after polling a new workflow task execution from
Temporal server, the SDK will check whether the given workflow task execution is already being
processed by a workflow task executor on any SDK worker node within the Erlang cluster.
If there is already a workflow executor processing the given workflow task execution, the polled
workflow task data is redirected to that workflow executor.
The workflow task executor, upon receiving a polled workflow execution task, validates the integrity
of the received workflow task, particularly by comparing the polled task's event history with its
internal executor event history.
If the polled task integrity checks pass, the workflow executor appends the newly polled workflow task
execution events history and proceeds further with the workflow task execution.
If no workflow executors are found processing polled workflow task execution, a new workflow task
executor process is spawned on the local worker node that polled given task.
Task executor processes are not supervised by OTP. Task executions are supervised by the Temporal
server using timeout-based mechanisms.

In the event of a split-brain state in the Erlang cluster, workflow executors are started on all
isolated Erlang cluster partitions Erlang nodes that polled workflow task execution.
Each workflow task executor will progress with workflow task execution until the workflow task
transitions to a closed state or another workflow executor advances the workflow execution further.

If `enable_single_distributed_workflow_execution` configuration option is set to false (not recommended),
after polling a new workflow task execution, the SDK will check whether the given workflow task
execution is already being processed by any workflow task executor running on the local Erlang node.
If there is already a workflow executor processing the given workflow task execution, the polled
workflow task will be redirected to that workflow executor, otherwise a new workflow executor process is
spawned on the local Erlang node.

Described above, single workflow execution per cluster is applied on a best-effort basis.
After a workflow task is polled from the server, at least one workflow execution will be processed
by the SDK workers cluster. If multiple executions are started, they may race to completion.
If the SDK workflow executor attempts to complete a workflow task via the
`RespondWorkflowTaskCompleted` gRPC call for a workflow execution that has already been
completed elsewhere, it will generate a `"Workflow task not found"` gRPC error.
Such errors are common for Temporal server and can usually be safely ignored.

SDK uses sharded `m::pg` process groups to register workflow task executors across the Erlang cluster
nodes. `t::temporal_sdk_node.opts/0` `scope_config` configuration option is used to specify the number of
process group shards per SDK cluster.
The default number of the workflow scope process group shards is set to 10, which should be sufficient
for most use cases.

### Workflow Sticky Execution

As described in the sections above, once the user initiates a workflow execution, the Temporal server
schedules the workflow task on the user-defined (regular) task queue, and the SDK starts the workflow
executor to process the polled task.
Poll process is handled by the gRPC `PollWorkflowTaskQueueRequest` and its corresponding
`PollWorkflowTaskQueueResponse`. The task poll response includes workflow execution history starting
from the first history event. Workflow history may already contain many events during workflow replay.
The number of history events returned in a single poll request is limited by the
`limit.historyMaxPageSize` Temporal server configuration option (default: 256). Any remaining events
must be fetched via additional `GetWorkflowExecutionHistoryRequest` gRPC calls.
The maximum number of events per such request is controlled by the `maximum_page_size` option
in `t::temporal_sdk_worker.workflow_settings/0` (default: 256).
From the above description of the regular task queue, one can observe a key drawback:
the entire workflow execution history must be retrieved from the Temporal server and reconstructed by
the SDK, potentially requiring multiple `GetWorkflowExecutionHistoryRequest` calls.

To optimize polling workflow events history Temporal provides a
[sticky execution](https://docs.temporal.io/sticky-execution) mechanism.
After workflow task is polled from regular task queue, workflow executor starts execution of the
user defined workflow implementation. During workflow execution Temporal workflow commands such as
`start_activity()` are collected by SDK. As soon as workflow execution cannot proceed further due to
pending results from collected Temporal commands, SDK sends collected commands to Temporal server with
`RespondWorkflowTaskCompletedRequest` gRPC call. In `RespondWorkflowTaskCompletedRequest` call, SDK
can indicate that future workflow history events should be provided as incremental events on a
sticky queue by setting `sticky_attributes`.

SDK sticky execution is configured using the `sticky_execution` worker option in workflow task settings.

The following sticky execution types are supported by this SDK:

- `disabled`: Disables sticky execution. This setting may be suitable, for example, for workflow
  implementations with a small number of long-running activities that sequentially process large payloads.
  Evicting workflow after each task completion and releasing memory used by the workflow executor could be
  beneficial in such cases. In such scenario, the `handle_eviction()` callback should always return `evict`.
  Note that disabling sticky execution for workflows with a large number of events may significantly
  degrade performance.
- `local`: Uses a local, dedicated sticky queue per workflow execution. This setting may be appropriate
  for example for workflows with many short-running activities, which could generate high load on sticky
  queue. SDK worker nodes are capable of handling an unlimited number of local sticky queues.
  When using this option, Temporal server limitations should be considered.
- `pool`: Uses a pool of sticky queue pollers per worker. This is the default and preferred option in
  most cases.

### Workflow Eviction

The workflow executor stores Temporal events in two ETS tables: an awaitables index table and an events
history table, for user convenience. As a result, the workflow executor's memory consumption is roughly
twice that of the current workflow events history.
After workflow commands are dispatched to the Temporal server with `RespondWorkflowTaskCompletedRequest`
gRPC call (as described above), workflow executor waits for new workflow tasks from the server.
New tasks can arrive via either the regular task queue or the sticky queue.
If the SDK waits for an extended period and the workflow events history is large, idle workflow executors
on worker nodes may require significant memory while awaiting tasks from the Temporal server.

To reduce resource usage on SDK worker nodes, workflow executors implement an eviction mechanism
that terminates the executor and releases its allocated resources.
Workflow eviction can be requested either before or after the `RespondWorkflowTaskCompletedRequest` gRPC call.

Two options are available to request workflow eviction before task completion via
`RespondWorkflowTaskCompletedRequest`:

- `:temporal_sdk_workflow.evict_workflow/0` SDK command,
- `evict` option in `t::temporal_sdk_workflow.await_opts/0`.

When a workflow is evicted before the `RespondWorkflowTaskCompletedRequest` the following sequence
occurs during workflow execution:

1. The `RespondWorkflowTaskCompletedRequest` `sticky_attributes` is not set, so the Temporal server knows
   in advance to dispatch the next workflow task to the regular task queue.
2. If the `RespondWorkflowTaskCompletedResponse` contains no eager tasks, the workflow executor is
   stopped, releasing its allocated resources.
3. Next workflow task is polled from regular task queue, and workflow is replayed by a new workflow executor
   instance.

During workflow replay, eviction requests described above are ignored.

Workflow can also be evicted via the `c::temporal_sdk_workflow.handle_eviction/2` callback function,
which is executed after the `RespondWorkflowTaskCompletedRequest` is processed.
If `handle_eviction/2` requests workflow eviction by returning `evict` the following sequence occurs:

1. The `RespondWorkflowTaskCompletedRequest` may include `sticky_attributes` set according to
   the `sticky_execution` setting discussed previously.
2. If the `RespondWorkflowTaskCompletedResponse` contains no eager tasks, the workflow executor is
   stopped, releasing its allocated resources.
3. Further behaviour depends on the `sticky_execution` `type` setting:

- If `sticky_execution` is set to `disabled`, the next workflow task is polled from the regular task
  queue and handled by a new workflow executor instance.
- If `sticky_execution` is set to `local`, a gRPC `ShutdownWorkerRequest` is issued during workflow
  executor shutdown to notify the server that the given (local) sticky queue will no longer be used.
  The next workflow task is then polled from the regular task queue and handled by a new workflow
  executor instance.
- If `sticky_execution` is set to `pool`, the next stale workflow task is polled from the worker's
  shared sticky queue. A new workflow executor is started using this stale task, which contains the
  events history starting from the last event processed by already evicted workflow executor. Missing
  history events are retrieved via a (multiple) `GetWorkflowExecutionHistoryRequest` and the workflow
  task is processed as in regular cases using reconstructed events history.

`RespondWorkflowTaskCompletedRequest` is never invoked during workflow replay, consequently
`handle_eviction/2` it never called during replay.

If the user does not provide an implementation for `handle_eviction/2`, the SDK uses a built-in
implementation.

The built-in `handle_eviction/2` implementation provides a "smart" eviction mechanism that depends
on three variables:

- Workflow history size,
- Workflow history event count,
- Executor idle time spent polling for new workflow tasks.

Workflows with large history sizes and few events are evicted quickly, as they require few
`GetWorkflowExecutionHistoryRequest` calls to reconstruct history and can release substantial memory.
Workflows with small history sizes and many events are evicted only after longer idle polling
durations, as they would require multiple `GetWorkflowExecutionHistoryRequest` calls, and the memory
released may be relatively small. See `c::temporal_sdk_workflow.handle_eviction/2` documentation for
more details.

Following [SDK Samples](https://github.com/andrzej-mag/temporal_sdk_samples) provide workflow eviction
example implementations:

- [Workflow Eviction](https://github.com/andrzej-mag/temporal_sdk_samples/tree/main/docs/workflow_eviction.md)
  demonstrates eviction using `handle_eviction/2`.
- [Eviction Parallel Handler](https://github.com/andrzej-mag/temporal_sdk_samples/tree/main/docs/eviction_parallel_handler.md) demonstrates eviction using `evict_workflow/0`.

## Rate Limiting

The OS rate limiter process is managed and supervised by the SDK node.
Concurrency and fixed window rate limiters are available at the SDK node, SDK cluster, and task worker
SDK hierarchy levels. They are depicted in the SDK Architecture diagram above as a "node rate
limiter", "cluster rate limiter", and "worker rate limiter".
Task worker task poller leaky bucket rate limiter is implemented within the task worker task poller state
machine and is represented as a "poller rate limiter" on the diagram above.

After a Temporal task is polled from the Temporal server by the task worker's task poller, the task
poller's state machine starts the task executor and then enters the `wait` state, where rate limiter
limits are checked and applied.
First, a time delay derived from the leaky bucket rate limiter settings is applied.
After the leaky bucket delay passes, limits checks are executed for OS, concurrency, and fixed window
rate limiters.

The task poller state machine remains in the `wait` state until the user-provided rate limiter limits
are exceeded.
Rate limits check frequency is configured via the `t::temporal_sdk_worker.opts/0`
`limiter_check_frequency` option.
As soon as the rate limiter limits are satisfied, the task poller state machine transitions from the
`wait` state to the `poll` state and polls the Temporal server for the next task execution.

Task poller state machine `wait` state transitions emit the following telemetry events:

- [`[temporal_sdk, poller, wait, start]`](`m::temporal_sdk_telemetry#module-temporal_sdk-poller-wait-start`)
- [`[temporal_sdk, poller, wait, stop]`](`m::temporal_sdk_telemetry#module-temporal_sdk-poller-wait-stop`)

Telemetry event `[temporal_sdk, poller, wait, start]` provides a `limiter_delay` measurement that
indicates the duration of the delay imposed by the leaky bucket rate limiter.
Telemetry event `[temporal_sdk, poller, wait, stop]` provides a `limited_by` measurement detailing
how long task pollers spend in the `wait` state when they exceed OS, concurrency or fixed window rate
limiters limits.

Concurrency and fixed window rate limiters limits configuration options are set per entire task poller pool.
A single SDK task poller state machine can theoretically poll thousands of tasks per second, although actual
performance is subject to Temporal server limitations. Accordingly, when setting concurrency or fixed
window frequency limits below a few hundred tasks per second, it is recommended to reduce the task poller
pool size to one or two pollers, subject to the given use case requirements. SDK will be unable to properly
handle rate limiting where the task poller's pool size exceeds the rate limiter concurrency or fixed
window frequency limits.

See also `m::temporal_sdk_limiter`.
