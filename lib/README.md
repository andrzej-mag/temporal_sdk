# Elixir Syntactic Wrapper

This directory contains the Elixir syntactic wrapper for the Temporal Erlang/Elixir SDK.

## Overview

The modules in this directory provide an idiomatic Elixir interface to the core Erlang implementation in the `src/` directory, designed to feel natural and intuitive for Elixir developers.

## Automated Delegation

To maintain strict parity between the Erlang core and the Elixir wrapper, most modules in this directory are automatically generated using the `TemporalSdk.Utils.Code.delegate_all/1` macro.

### How it Works

The `delegate_all` macro performs the following tasks at compile time:

1. **Documentation Import**: It automatically imports module and function documentation from the Markdown files in the `docs/` directory, as defined in the corresponding Erlang source.
2. **Function Delegation**: It scans the corresponding Erlang source file and generates Elixir functions that delegate directly to the Erlang implementation.
3. **Typespec Translation**: It converts Erlang `-spec` attributes into Elixir `@spec` attributes, ensuring type information is preserved and accessible in Elixir’s hexdocs documentation.

### Example Usage

```elixir
defmodule TemporalSdk do
  import TemporalSdk.Utils.Code
  delegate_all(from: "src/temporal_sdk/temporal_sdk.erl")
end
```

By using this approach, any new features, bug fixes, or documentation updates added to the Erlang core are automatically reflected in the Elixir wrapper without manual intervention.
