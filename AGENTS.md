# AGENTS

This document provides specialized guidance for AI agents contributing to the Temporal Erlang/Elixir SDK.

## Table of Contents

1. [Required Expertise](#required-expertise)
2. [Project Overview](#project-overview)
3. [Project Structure](#project-structure)
4. [Core Architecture](#core-architecture)
5. [Development Guidelines](#development-guidelines)
6. [Documentation Standards](#documentation-standards)
7. [Testing Strategy](#testing-strategy)
8. [Code Quality & Tooling](#code-quality--tooling)
9. [Project Status](#project-status)

---

## REQUIRED EXPERTISE

- **Erlang & OTP**: Advanced knowledge of Erlang and OTP design patterns.
- **Elixir**: Proficiency in Elixir, including macros and interoperability with Erlang.
- **Temporal**: Deep understanding of Temporal server concepts (Workflows, Activities, Signals, Queries).
- **gRPC & Protobuf**: Experience with gRPC communication and Protocol Buffers.
- **Distributed Systems**: Familiarity with concurrency, consistency, and distributed state.

## PROJECT OVERVIEW

The Temporal SDK is a framework for authoring workflows and activities in Erlang and Elixir. It faithfully implements the Temporal server's behavior and APIs, providing a robust platform for long-running, fault-tolerant processes.

## PROJECT STRUCTURE

```text
.
├── _*/                     # Directories with ephemeral files which should be ignored
├── docs/                   # Markdown documentation (shared between Erlang/Elixir)
├── guides/                 # User guides and quick-start materials
├── include/                # Erlang include files
├── lib/                    # Elixir syntactic wrapper (delegates to Erlang)
├── proto/                  # Temporal API protocol buffers (git submodule)
├── src/                    # Core Erlang implementation
│   ├── api/                # API definitions and interfaces
│   ├── client/             # gRPC client implementation
│   ├── cluster/            # SDK cluster management
│   ├── codec/              # Temporal payload codec
│   ├── executor/           # Workflow, Activity, and Nexus task executors
│   ├── grpc/               # gRPC communication layer
│   ├── limiter/            # concurency, fixed window and OS rate limiters
│   ├── node/               # SDK node implementation
│   ├── poller/             # Polling mechanisms for task queues
│   ├── proto/              # Temporal API protocol buffer definitions
│   ├── scope/              # SDK scoping mechanisms
│   ├── telemetry/          # Telemetry collection and reporting
│   ├── temporal_sdk/       # Primary user-facing Erlang interface
│   ├── utils/              # Utilities
│   └── worker/             # Temporal task workers management
├── test/                   # General Erlang eunit tests
├── test_ex/                # Elixir ExUnit tests
├── test_replay/            # Specialized replay tests for workflow determinism
├── mix.exs                 # Mix project configuration
├── rebar.config            # Rebar3 project configuration
├── README.md               # Project README documentation
├── AGENTS.md               # This file - guidance for AI agents
└── .gitignore              # Files and directories to git-ignore
```

## CORE ARCHITECTURE

### Dual-Language Synergy

- **Erlang (Core)**: The engine is built in Erlang for maximum stability and performance.
- **Elixir (Wrapper)**: The `lib/` directory contains an idiomatic Elixir layer. Most Elixir modules are automatically generated using the `TemporalSdk.Utils.Code.delegate_all` macro to ensure perfect parity with the Erlang source.

### Execution Model

- **Executors**: The `src/executor/` modules handle the lifecycle of Temporal tasks.
- **Process Dictionary**: The `temporal_sdk_executor` utilizes the process dictionary to store execution-local context (e.g., execution ID, API context, OTel context). Use the provided getters/setters in `temporal_sdk_executor.erl` rather than accessing the dictionary directly.

## DEVELOPMENT GUIDELINES

- **Maintain Parity**: Ensure that any change to the Erlang core is reflected or appropriately exposed in the Elixir wrapper.
- **Deterministic Workflows**: Workflows must be deterministic. Avoid using functions that introduce side effects (e.g., `erlang:now/0`, random numbers) directly within workflow logic.
- **Separation of Concerns**: Keep API definitions (`src/api/`) distinct from the underlying execution logic (`src/executor/`).
- **OTP Compliance**: Adhere strictly to OTP patterns. Use supervisors for process trees and `gen_server` for stateful components.

## DOCUMENTATION STANDARDS

- **Shared Documentation**: Documentation is stored in `docs/` and shared between Erlang and Elixir.
- **File Naming**:
  - Modules: `docs/<path>/-module.md`
  - Functions: `docs/<path>/<function>-<arity>.md`
- **Importing**:
  - Erlang: Use `-moduledoc {file, Path}` and `-doc {file, Path}`.
  - Elixir: Handled automatically via `delegate_all`.
- **Formatting**:
  - Hard-wrap at 100 characters.
  - Start with a concise one-paragraph summary.
  - Use `-moduledoc false` or `-doc false` for internal/private components.

## TESTING STRATEGY

### Replay Testing

Replay tests (`test_replay/`) are critical. They verify that workflows remain deterministic by replaying history against current code.

- Use `?assertReplayEqual` and `?assertReplayMatch` for verification.
- Use `?THROW_ON_REPLAY` to test failure handling during execution without breaking replay.

### Execution

- **Unit Tests**: Use `rebar3 eunit -m <module>` to run specific test suites. Avoid running the full suite unless necessary, as it is time-consuming.
- **ExUnit**: Use `mix test` for Elixir-specific tests in `test_ex/`.

## CODE QUALITY & TOOLING

- **Static Analysis**: Run `rebar3 dialyzer` and `mix dialyzer`.
- **Type Checking**: Use `elp eqwalize-all` for comprehensive type validation.
- **Linting**: Use `elp lint` to maintain code style consistency.
- **Versioning**: Follow [Conventional Commits](https://www.conventionalcommits.org/).

## PROJECT STATUS

- **Active Development**: The SDK is evolving rapidly. Refer to `TODO.md` for the current roadmap.
- **Test Coverage**: Significant effort is underway to recover and modernize unit tests. Be cautious with existing "offline" tests.
