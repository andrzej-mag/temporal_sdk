[![Hex Version](https://img.shields.io/hexpm/v/temporal_sdk?style=for-the-badge)](https://hex.pm/packages/temporal_sdk)
[![Hex Docs](https://img.shields.io/badge/hex-docs-informational?style=for-the-badge)](https://hexdocs.pm/temporal_sdk)

> Project status: work in progress.
> The [TODO.md](TODO.md) file can be considered as a project progress tracker.

[Temporal](https://temporal.io/) is a distributed, scalable, durable, and highly available
orchestration engine used to execute asynchronous, long-running business logic in a scalable
and resilient way.

Temporal Erlang SDK is the framework for authoring workflows and activities using the Erlang
programming language.

## Quick Start

Add `temporal_sdk` to your application dependencies list:

```erlang
%% rebar3.config
{deps, [
    temporal_sdk
]}.

%% my_application.app.src
{application, my_application, [
    {applications, [
        temporal_sdk
    ]}
]}.
```

Configure `temporal_sdk` to start activity and workflow workers during application startup
(see [`temporal_sdk_node`](https://hexdocs.pm/temporal_sdk/temporal_sdk_node.html),
[`temporal_sdk_cluster`](https://hexdocs.pm/temporal_sdk/temporal_sdk_cluster.html) and
[`temporal_sdk_worker`](https://hexdocs.pm/temporal_sdk/temporal_sdk_worker.html)):

```erlang
%% sys.config
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

Above SDK configuration assumes that Temporal server is available on `localhost:7233`.
Refer to [temporal_sdk_samples](https://github.com/andrzej-mag/temporal_sdk_samples#requirements)
repository for Temporal CLI dev server setup instructions.

Define `hello_world_activity`
(see [`temporal_sdk_activity`](https://hexdocs.pm/temporal_sdk/temporal_sdk_activity.html)):

```erlang
%% hello_world_activity.erl
-module(hello_world_activity).

-export([execute/2]).

-include_lib("temporal_sdk/include/activity.hrl").

execute(_Context, [String]) -> [string:uppercase(String)].
```

Define `hello_world_workflow`
(see [`temporal_sdk_workflow`](https://hexdocs.pm/temporal_sdk/temporal_sdk_workflow.html)):

```erlang
%% hello_world_workflow.erl
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

Start `rebar3 shell` and run `hello_world_workflow` workflow execution:

```erlang
1> hello_world_workflow:start().
HELLO WORLD from Temporal
...
```

This and other examples can be found in the
[temporal_sdk_samples](https://github.com/andrzej-mag/temporal_sdk_samples) repository.

## License

Temporal Erlang SDK is distributed under a [Business Source License (BSL)](LICENSE.txt).

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
