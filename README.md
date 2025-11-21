[![Hex Version](https://img.shields.io/hexpm/v/temporal_sdk?style=for-the-badge)](https://hex.pm/packages/temporal_sdk)
[![Hex Docs](https://img.shields.io/badge/hex-docs-informational?style=for-the-badge)](https://hexdocs.pm/temporal_sdk)

> Project status: work in progress - under active development.
> The [TODO.md](TODO.md) file can be considered as a project progress tracker.

[Temporal](https://temporal.io/) is a distributed, scalable, durable, and highly available
orchestration engine used to execute asynchronous, long-running business logic in a scalable
and resilient way.

Temporal Erlang and Elixir SDK is a framework for authoring workflows and activities using the
Erlang and Elixir programming languages.

## Quick Start

Add `temporal_sdk` to your application runtime dependencies list:

<!-- tabs-open -->

#### Elixir

```elixir
# mix.exs
  defp deps do
    [
      {:temporal_sdk, ">= 0.0.0"}
    ]
  end
```

#### Erlang

```erlang
%% rebar3.config
{deps, [
    temporal_sdk
]}.

%% src/hello_world.app.src
{application, hello_world, [
    {applications, [
        temporal_sdk
    ]}
]}.
```

<!-- tabs-close -->

Configure activity and workflow runtime [workers](https://docs.temporal.io/workers):

<!-- tabs-open -->

#### Elixir

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

#### Erlang

```erlang
%% config/sys.config
[
    {temporal_sdk, [
        {clusters, [
            {cluster_1, [
                {activities, [#{task_queue => "default"}]},
                {workflows, [#{task_queue => "default"}]}
            ]}
        ]}
    ]}
].
```

<!-- tabs-close -->

Implement Temporal [activity definition](https://docs.temporal.io/activity-definition):

<!-- tabs-open -->

#### Elixir

```elixir
# lib/hello_world_activity.ex
defmodule HelloWorld.Activity do
  use TemporalSdk.Activity

  @impl true
  def execute(_context, [string]), do: [String.upcase(string)]
end
```

#### Erlang

```erlang
%% src/hello_world_activity.erl
-module(hello_world_activity).

-export([execute/2]).

-include_lib("temporal_sdk/include/activity.hrl").

execute(_Context, [String]) -> [string:uppercase(String)].
```

<!-- tabs-close -->

Implement Temporal [workflow definition](https://docs.temporal.io/workflow-definition):

<!-- tabs-open -->

#### Elixir

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

#### Erlang

```erlang
%% src/hello_world_workflow.erl
-module(hello_world_workflow).

-export([execute/2, start/0]).

-include_lib("temporal_sdk/include/workflow.hrl").

execute(_Context, Input) ->
    A1 = start_activity(hello_world_activity, ["hello"]),
    A2 = start_activity(hello_world_activity, ["world"]),
    [#{result := A1Result}, #{result := A2Result}] = wait_all([A1, A2]),
    io:fwrite("~s ~s ~s~n~n", [A1Result, A2Result, Input]).

start() ->
    temporal_sdk:start_workflow(cluster_1, "default", hello_world_workflow, [
        wait, {input, ["from Temporal"]}
    ]).
```

<!-- tabs-close -->

Start  `iex -S mix` or `rebar3 shell` and run Temporal
[workflow execution](https://docs.temporal.io/workflow-execution):

<!-- tabs-open -->

#### Elixir

```elixir
iex(1)> HelloWorld.Workflow.start()
HELLO WORLD from Temporal
...
```

#### Erlang

```erlang
1> hello_world_workflow:start().
HELLO WORLD from Temporal
...
```

<!-- tabs-close -->

This and other examples can be found in the
[temporal_sdk_samples](https://github.com/andrzej-mag/temporal_sdk_samples) repository.

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
When creating your first Pull Request, please copy and paste the following acknowledgement as a PR
comment:

```text
I have read the Individual Contributor License Agreement (ICLA) and I hereby sign the ICLA.
```
