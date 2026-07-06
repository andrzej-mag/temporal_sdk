[![Hex Version](https://img.shields.io/hexpm/v/temporal_sdk?style=for-the-badge)](https://hex.pm/packages/temporal_sdk)
[![Hex Docs](https://img.shields.io/badge/hex-docs-informational?style=for-the-badge)](https://hexdocs.pm/temporal_sdk)

> Project status: work in progress - under active development.
> The [TODO.md](TODO.md) file can be considered as a project progress tracker.

[Temporal](https://temporal.io/) is a distributed, scalable, durable, and highly available
orchestration engine used to execute asynchronous, long-running business logic in a scalable
and resilient way.

Temporal Erlang/Elixir SDK is a framework for authoring workflows and activities using the
Erlang and Elixir programming languages.

The Erlang/Elixir SDK is a native Temporal SDK implemented in Erlang, with a lightweight Elixir wrapper.
SDK doesn't use any NIFs or ports.
SDK connects directly to Temporal Cluster(s) using built-in gRPC client.
By implementing the
[temporal_sdk_grpc_adapter](https://temporal-sdk.hexdocs.pm/temporal_sdk_grpc_adapter.html) behaviour,
any HTTP/2 adapter can be used for gRPC transport.
The [gun](https://hex.pm/packages/gun) package is used as the default HTTP/2 adapter.
[Temporal gRPC API](https://github.com/temporalio/api) protocol buffers are compiled using an external
Erlang script based on the [gpb](https://hex.pm/packages/gpb) package.

Native Erlang SDK implementation leverages OTP's unique capabilities to deliver features unavailable
in other SDKs, for example:

- Flexible workflow eviction based on individual workflow execution properties and business logic,
  rather than a simple LRU policy used in other SDKs. This feature enables optimization of worker
  node infrastructure costs, especially for long-running workflows.
  [[docs]](https://temporal-sdk.hexdocs.pm/architecture.html#workflow-eviction),
  [[sample 1]](https://github.com/andrzej-mag/temporal_sdk_samples/blob/main/docs/workflow_eviction.md),
  [[sample 2]](https://github.com/andrzej-mag/temporal_sdk_samples/blob/main/docs/eviction_parallel_handler.md).
- Flexible dynamic concurrency, fixed window and leaky bucket Temporal tasks rate limiters.
  [[docs]](https://temporal-sdk.hexdocs.pm/architecture.html#rate-limiting),
  [[sample]](https://github.com/andrzej-mag/temporal_sdk_samples/blob/main/docs/rate_limiter.md).
- Parallel workflow executions and composable `await()` functions simplify the implementation of
  workflow business logic.
  [[sample 1]](https://github.com/andrzej-mag/temporal_sdk_samples/blob/main/docs/parallel_execution.md),
  [[sample 2]](https://github.com/andrzej-mag/temporal_sdk_samples/blob/main/docs/saga.md).
- Ergonomic and flexible handling of activity heartbeats.
  [[sample]](https://github.com/andrzej-mag/temporal_sdk_samples/blob/main/docs/activity_heartbeat.md).
- Temporal events are a first-class SDK feature and can be awaited using composable `await()` functions.
  [[sample 1]](https://github.com/andrzej-mag/temporal_sdk_samples/blob/main/docs/awaitable_event.md),
  [[sample 2]](https://github.com/andrzej-mag/temporal_sdk_samples/blob/main/docs/event_handler.md),
  [[sample 3]](https://github.com/andrzej-mag/temporal_sdk_samples/blob/main/docs/signal_parallel_handler.md).
- ETS tables store workflow awaitables and raw Temporal events, enabling querying of workflow event
  histories using ETS query semantics.
  [[sample]](https://github.com/andrzej-mag/temporal_sdk_samples/blob/main/docs/workflow_cancel_parallel.md).
- Mutable markers that can reset-mutate workflow execution during workflow replay, for example, in
  response to environmental variable changes (experimental feature).
  [[sample]](https://github.com/andrzej-mag/temporal_sdk_samples/blob/main/docs/mutable_marker.md).
- OTP messages handling in workflows and activities (WIP). Feature will, for example, improve
  performance for workflow pseudo-signals/queries dispatched as OTP messages with fallback to regular
  signal/query if live workflow execution is not available in the worker nodes cluster.

## Quick Start (Elixir)

Full code for the following `HelloWorld` example, along with other code samples, can be found in the
[temporal_sdk_samples](https://github.com/andrzej-mag/temporal_sdk_samples) repository.
Please refer to the documentation
[Quick Start guide](https://hexdocs.pm/temporal_sdk/quick_start.html) for an extended version of
this example with Erlang code snippets.

Add `temporal_sdk` to your application dependencies list:

```elixir
# mix.exs
  defp deps do
    [
      {:temporal_sdk, ">= 0.0.0"}
    ]
  end
```

Configure `:cluster_1` [SDK cluster](https://hexdocs.pm/temporal_sdk/TemporalSdk.Cluster.html) with
activity and workflow runtime [task workers](https://docs.temporal.io/workers) that poll for tasks
from the `"default"` activity and workflow [task queues](https://docs.temporal.io/task-queue):

```elixir
# config/config.exs
config :temporal_sdk,
  clusters: [
    cluster_1: [
      activities: [[task_queue: "default"]],
      workflows: [[task_queue: "default"]]
    ]
  ]
```

Implement Temporal [activity definition](https://docs.temporal.io/activity-definition):

```elixir
# lib/hello_world_activity.ex
defmodule HelloWorld.Activity do
  use TemporalSdk.Activity

  @impl true
  def execute(_context, [[string]]), do: [[String.upcase(string)]]
end
```

Implement Temporal [workflow definition](https://docs.temporal.io/workflow-definition) and a
`start/0` helper function that starts and awaits the execution of `HelloWorld.Workflow` workflow:

```elixir
# lib/hello_world_workflow.ex
defmodule HelloWorld.Workflow do
  use TemporalSdk.Workflow

  @impl true
  def execute(_context, input) do
    a1 = start_activity(HelloWorld.Activity, [["hello"]])
    a2 = start_activity(HelloWorld.Activity, [["world"]])
    [%{result: a1_result}, %{result: a2_result}] = wait_all([a1, a2])
    IO.puts("#{a1_result} #{a2_result} #{input} \n")
  end

  def start do
    TemporalSdk.start_workflow(:cluster_1, "default", HelloWorld.Workflow, [
      :wait,
      input: [["from Temporal"]]
    ])
  end
end
```

Start  `iex -S mix` and run Temporal
[workflow execution](https://docs.temporal.io/workflow-execution):

```elixir
iex(1)> HelloWorld.Workflow.start()
HELLO WORLD from Temporal
...
```

### Requirements

The basic `config.exs` configuration file provided above assumes an unsecured Temporal server running
on `localhost:7233`.
For development and testing purposes it is recommended to run the
[Temporal CLI](https://github.com/temporalio/cli/) locally:

1. [Install](https://docs.temporal.io/cli#install) Temporal CLI.
2. [Start](https://docs.temporal.io/cli#start-dev-server) Temporal CLI dev server.

## License

Temporal Erlang/Elixir SDK is distributed under the [Business Source License (BSL)](LICENSE.txt).

For more information on the use of the BSL generally, please visit the
[Adopting and Developing Business Source License FAQ](https://mariadb.com/bsl-faq-adopting/).

## Pricing

The software monthly subscription fee is €100 (plus VAT/tax where applicable) per production application
that uses this SDK as a dependency.

To subscribe or manage your subscription, please visit the [Subscription Management Link TBA].

## Sponsoring

The Temporal Erlang/Elixir SDK is under active development. Financial sponsorship helps sustain work
on this project.
To discuss sponsorship, contact me via the links on my
[hex.pm profile](https://hex.pm/users/andrzej-mag) or open a thread in
[GitHub Discussions](https://github.com/andrzej-mag/temporal_sdk/discussions).

## Contributing

Contributors must agree to the [Individual Contributor License Agreement](ICLA.txt).
When creating your first pull request, please copy and paste the following acknowledgment as your first commit message:

```text
I have read the Individual Contributor License Agreement (ICLA) and hereby sign the ICLA.
```
