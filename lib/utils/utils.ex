defmodule TemporalSdk.Utils do
  @moduledoc false

  @spec exdoc!(erlang_docs_path :: Path.t()) :: elixir_docs :: String.t()
  def exdoc!(erlang_docs_path),
    do:
      erlang_docs_path
      |> File.read!()
      |> String.replace("`m:", "`m::")
end
