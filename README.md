[![Hex Version](https://img.shields.io/hexpm/v/temporal_sdk?style=for-the-badge)](https://hex.pm/packages/temporal_sdk)
[![Hex Docs](https://img.shields.io/badge/hex-docs-informational?style=for-the-badge)](https://hexdocs.pm/temporal_sdk)

> Project status: work in progress - under active development.
> The [TODO.md](TODO.md) file can be considered as a project progress tracker.

[Temporal](https://temporal.io/) is a distributed, scalable, durable, and highly available
orchestration engine used to execute asynchronous, long-running business logic in a scalable
and resilient way.

Temporal Erlang and Elixir SDK is a framework for authoring workflows and activities using the
Erlang and Elixir programming languages.

## Quick Start (Elixir)

The [temporal_sdk_samples](https://github.com/andrzej-mag/temporal_sdk_samples) repository
contains this and other code samples. Please refer to the documentation
[Quick Start guide](https://hexdocs.pm/temporal_sdk/quick_start.html) for the extended version of
this example with Erlang code snippets.

Add `temporal_sdk` to your application runtime dependencies list:

```elixir
# mix.exs
  defp deps do
    [
      {:temporal_sdk, ">= 0.0.0"}
    ]
  end
```

Configure activity and workflow runtime task [workers](https://docs.temporal.io/workers):

```elixir
# config/config.exs
config :temporal_sdk,
  clusters: [
    cluster_1: [
      activities: [%{:task_queue => "default"}],
      workflows: [%{:task_queue => "default"}]
    ]
  ]
```

Implement Temporal [activity definition](https://docs.temporal.io/activity-definition):

```elixir
# lib/hello_world_activity.ex
defmodule HelloWorld.Activity do
  use TemporalSdk.Activity

  @impl true
  def execute(_context, [string]), do: [String.upcase(string)]
end
```

Implement Temporal [workflow definition](https://docs.temporal.io/workflow-definition):

```elixir
# lib/hello_world_workflow.ex
defmodule HelloWorld.Workflow do
  use TemporalSdk.Workflow

  @impl true
  def execute(_context, input) do
    a1 = start_activity(HelloWorld.Activity, ["hello"])
    a2 = start_activity(HelloWorld.Activity, ["world"])
    [%{result: a1_result}, %{result: a2_result}] = wait_all([a1, a2])
    IO.puts("#{a1_result} #{a2_result} #{input} \n")
  end

  def start do
    TemporalSdk.start_workflow(:cluster_1, "default", HelloWorld.Workflow, [
      :wait,
      input: ["from Temporal"]
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

## Requirements

Temporal server running locally or available on `localhost:7233`.
For development and testing purposes it is recommended to use
[Temporal CLI](https://github.com/temporalio/cli/):

1. [Install](https://docs.temporal.io/cli#install) Temporal CLI.
2. [Start](https://docs.temporal.io/cli#start-dev-server) Temporal CLI dev server.

## License

Temporal Erlang and Elixir SDK is distributed under a [Business Source License (BSL)](LICENSE.txt).

For more information on the use of the BSL generally, please visit the
[Adopting and Developing Business Source License FAQ](https://mariadb.com/bsl-faq-adopting/).

## Pricing

The software monthly subscription fee is €100 (plus VAT/tax if applicable) per production application
that uses this SDK as a dependency.

To subscribe or manage your subscription please visit the [Subscription Management Link TBA].

## Contributing

Contributors must agree to the [Individual Contributor License Agreement](ICLA.txt).
When creating your first pull request, please copy and paste the following acknowledgement as a
first commit message:

```text
I have read the Individual Contributor License Agreement (ICLA) and I hereby sign the ICLA.
```
