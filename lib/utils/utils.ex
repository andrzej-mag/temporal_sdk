defmodule TemporalSdk.Utils do
  @moduledoc false

  @spec exdoc!(erlang_docs_path :: Path.t()) :: elixir_docs :: String.t()
  def exdoc!(erlang_docs_path),
    do:
      erlang_docs_path
      |> File.read!()
      |> String.replace("`c:", "`c::")
      |> String.replace("`e:", "`e::")
      |> String.replace("`m:", "`m::")
      |> String.replace("`t:", "`t::")
end
