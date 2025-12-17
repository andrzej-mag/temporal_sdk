# AGENTS

This file provides guidance to AI Agents when working with code in this project.

## REQUIRED EXPERTISE

- Erlang programming language
- OTP (Open Telecom Platform) design patterns
- Elixir programming language
- Temporal server concepts and gRPC API
- Protocol Buffers (protobuf) and gRPC
- Concurrent programming and distributed systems

## PROJECT OVERVIEW

The Temporal SDK is a framework for authoring workflows and activities using Erlang and Elixir programming languages. SDK faithfully implements the Temporal server's behavior and APIs.

## PROJECT STRUCTURE

```
.
├── _*/                     # Directories with ephemeral files which should be ignored
├── docs/                   # SDK documentation files
├── guides/                 # SDK user guides files
├── include/                # Erlang include files
├── lib/                    # Elixir syntactic wrapper SDK implementation
├── src/                    # Erlang core SDK implementation
│   ├── node/               # SDK node implementation
│   ├── api/                # API definitions and interfaces
│   ├── client/             # gRPC client implementation
│   ├── cluster/            # Temporal clusters management
│   ├── executor/           # Temporal workflow, activity and nexus execution logic
│   ├── grpc/               # gRPC communication layer
│   ├── poller/             # Polling mechanisms for task queues
│   ├── proto/              # Temporal API protocol buffer definitions
│   ├── scope/              # SDK scoping mechanisms
│   ├── telemetry/          # Telemetry collection and reporting
│   └── worker/             # Temporal workers management
├── test/                   # Erlang eunit tests
├── test_ex/                # Elixir wrapper ExUnit tests
├── test_replay/            # Temporal replay Erlang eunit tests
├── mix.exs                 # Mix project configuration
├── rebar.config            # Rebar3 project configuration
├── README.md               # Project README documentation
├── AGENTS.md               # This file - guidance for AI agents
└── .gitignore              # Files and directories to ignore
```

## CORE COMPONENTS

- **Elixir Wrapper**: Elixir syntactic sugar in `lib/` directory
- **Core Implementation**: Erlang-based implementation in `src/` directory
- **API Layer**: Contains the core API definitions in `src/api/`
- **Execution Engine**: Temporal workflow, activity and nexus execution logic in `src/executor/`
- **Communication**: gRPC layer in `src/grpc/` for interacting with Temporal server
- **Workers**: Temporal task workers management in `src/worker/`
- **Cluster Management**: Temporal clusters management in `src/cluster/`
- **Polling**: Task queue polling mechanisms in `src/poller/`
- **Protocol Buffers**: Temporal API protocol buffer definitions in `src/proto/`
- **Telemetry**: Metrics, logs, and traces collection in `src/telemetry/`

## TEMPORAL CONCEPTS TO UNDERSTAND

- **Workflows**: Long-running processes that orchestrate activities
- **Activities**: Short-running tasks executed within workflows
- **Task Queues**: Mechanism for distributing tasks to workers
- **Signals**: Mechanism for sending data into running workflows
- **Queries**: Mechanism for querying the state of running workflows
- **Child Workflows**: Workflows that are started by other workflows
- **Nexus**: Service integration points for external systems
- **Workflow Updates**: Mechanism for modifying running workflows
- **Worker Versioning**: Capability to manage different versions of workers

## GENERAL GUIDANCE

- **Understand the dual-language architecture**: Erlang (core) and Elixir (syntactic wrapper)
- **Familiarize yourself with the Temporal server concepts and API**
- **Pay attention to the separation between API definitions and implementation**
- **Respect the Erlang/OTP design patterns**: Use supervisors, gen_servers, and proper process management
- **Understand the gRPC communication layer**: The SDK communicates with Temporal server via gRPC
- **Comprehend the modular architecture**: Each component has a specific role in the overall system

## TEMPORAL SPECIFIC GUIDANCE

- **Workflow Execution**: Understand how workflows are scheduled, executed, and managed
- **Activity Execution**: Know how activities are scheduled, executed, and their lifecycle
- **Task Queues**: Understand how task queues work in Temporal and how they're managed
- **Error Handling**: Be aware of how failures and retries are handled in Temporal
- **State Management**: Understand how state is persisted and managed in workflows
- **Workflow Updates**: Understand how workflow updates are implemented
- **Worker Versioning**: Know how worker versioning works in the SDK
- **Nexus Integration**: Understand how external services are integrated via Nexus

## DOCUMENTATION GUIDANCE

- Documentation is stored in external files located in the `docs/` directory
- Documentation files are shared between the corresponding Elixir and Erlang modules. For example, the Erlang module `temporal_sdk_node` has the same documentation as the Elixir module `TemporalSdk.Node`
- Documentation directory layout corresponds to the Erlang `src` directory layout. For example, `temporal_sdk_node` documentation is stored in the `docs/node` directory
- By convention, module documentation is stored in the `-module.md` file
- Erlang module documentation is imported with `-moduledoc {file, FilePath}`, for example: `-moduledoc {file, "../../docs/node/-module.md"}.`
- Elixir module documentation is imported with `@moduledoc File.read!(file_path)`, for example: `@moduledoc File.read!("docs/node/-module.md")`
- By convention, function documentation is stored in separate markdown files, where the file name is a combination of the function name and function arity separated by a dash. For example: `docs/node/list-0.md` contains documentation for `temporal_sdk_node:list/0`
- Erlang function documentation is imported with `-doc {file, FilePath}`, for example: `-doc {file, "../../docs/node/list-0.md"}.`
- Elixir function documentation is imported with `@doc File.read!(file_path)`, for example: `@doc File.read!("docs/node/list-0.md")`
- The module documentation file should start with a short paragraph describing the module and then go into greater details
- The function documentation file should start with a short paragraph describing the function and then go into greater details
- Exclude documentation generation for modules containing the `-moduledoc false` attribute
- Exclude documentation generation for functions marked with the `-doc false` attribute
- Documentation text in markdown files must be hard wrapped to maintain a line length of 100 characters.

## CONTRIBUTION GUIDELINES

- Follow the existing code style and patterns
- Ensure both Erlang and Elixir implementations are kept in sync
- Add comprehensive tests for new functionality
- Update documentation appropriately
- Follow the [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) style for commit messages
- Keep dependencies updated
- Monitor for breaking changes in Temporal server API
- Maintain code quality through the use of code quality checking tools

## TESTING

- Don't run full set of project tests as it would require substantial amount of time
- Run only required tests by leveraging '-m' option for `rebar3 eunit`

## CODE QUALITY

- Run `rebar3 dialyzer` and `mix dialyzer` for static analysis
- Run `elp eqwalize-all` for type checking
- Run `elp lint` for linting

## PROJECT STATUS

- Project is under active development
- The `TODO.md` file can be considered as a project progress tracker
