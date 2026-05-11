defmodule TemporalSdk.Utils do
  @moduledoc false

  @spec exdoc!(Path.t()) :: String.t()
  def exdoc!(erlang_docs_path), do: erlang_docs_path |> File.read!() |> translate_doc()

  def translate_doc(doc_string),
    do:
      Regex.replace(~r/(?<!`)`([^`]+)`(?!`)/, doc_string, fn _, snippet -> "`#{ts(snippet)}`" end)

  def ts(erl_code) do
    cond do
      String.starts_with?(erl_code, "c:") ->
        tx = String.slice(erl_code, 2..-1//1) |> to_elixir(true)
        "c:#{tx}"

      String.starts_with?(erl_code, "t:") ->
        tx = String.slice(erl_code, 2..-1//1) |> to_elixir(true)
        "t:#{tx}"

      String.starts_with?(erl_code, "e:") ->
        [fmod | rest] = String.split(erl_code, "#", parts: 2, trim: true)
        mod = String.slice(fmod, 2..-1//1)

        tx_mod =
          case String.contains?(mod, "/") do
            false -> tx_mod(mod)
            true -> to_elixir(mod, false)
          end

        case rest do
          [] -> "e:#{tx_mod}"
          _ -> "e:#{tx_mod}##{rest}"
        end

      String.starts_with?(erl_code, "m:") ->
        [mod | rest] = String.split(erl_code, "#", parts: 2, trim: true)
        tx_mod = String.slice(mod, 2..-1//1) |> tx_mod()

        case rest do
          [] -> "m:#{tx_mod}"
          _ -> "m:#{tx_mod}##{rest}"
        end

      true ->
        to_elixir(erl_code, false)
    end
  end

  def to_elixir(code, is_erl) do
    with {:ok, tokens, _} <- :erl_scan.string(to_charlist(code <> ".")),
         {:ok, [ast]} <- :erl_parse.parse_exprs(tokens) do
      do_to_elixir(ast, is_erl)
    else
      _ -> code
    end
  end

  defp do_to_elixir(ast, is_erl) do
    case tx(ast, is_erl) do
      str when is_binary(str) -> str
      other -> Macro.to_string(other)
    end
  end

  # -------------------------------------------------------------------------------------------------
  # AST translation logic

  defp tx({:atom, _, value}, _), do: value
  defp tx({:integer, _, value}, _), do: value
  defp tx({:float, _, value}, _), do: value

  defp tx({:string, _, chars}, _), do: "\"#{List.to_string(chars)}\""
  # alternative:
  # defp tx({:string, _, chars}, _), do: List.to_string(chars)

  defp tx({:bin, 1, [{:bin_element, 1, {:string, 1, val}, :default, [:utf8]}]}, _),
    do: List.to_string(val)

  defp tx({:tuple, _, el}, is_erl), do: Enum.map(el, fn e -> tx(e, is_erl) end) |> List.to_tuple()

  defp tx({:map, _, fields}, is_erl),
    do:
      {:%{}, [],
       Enum.map(fields, fn {:map_field_assoc, _, k, v} -> {tx(k, is_erl), tx(v, is_erl)} end)}

  defp tx({:cons, _, head, tail}, is_erl), do: [tx(head, is_erl) | tx(tail, is_erl)]
  defp tx({nil, _}, _), do: []

  defp tx(
         {:op, _, :/, {:remote, _, {:atom, _, mod}, {:atom, _, fun}}, {:integer, _, arity}},
         false
       ),
       do: "#{tx_mod(mod)}.#{fun}/#{arity}"

  defp tx(
         {:op, _, :/, {:remote, _, {:atom, _, mod}, {:atom, _, fun}}, {:integer, _, arity}},
         true
       ),
       do: ":#{mod}.#{fun}/#{arity}"

  defp tx({:op, _, :/, {:atom, _, fun}, {:integer, _, arity}}, _), do: "#{fun}/#{arity}"

  defp tx({:call, _, {:atom, _, name}, args}, is_erl),
    do: {name, [], Enum.map(args, fn a -> tx(a, is_erl) end)}

  defp tx({:var, _, name}, _),
    do:
      name
      |> Atom.to_string()
      |> Macro.underscore()
      |> String.to_atom()
      |> then(fn snake_name -> {snake_name, [], nil} end)

  defp tx(other, _), do: other

  # -------------------------------------------------------------------------------------------------
  # SDK modules translation logic

  defp tx_mod(mod) when is_atom(mod), do: mod |> Atom.to_string() |> tx_mod()

  defp tx_mod("temporal_sdk"), do: "TemporalSdk"
  defp tx_mod("temporal_sdk_batch"), do: "TemporalSdk.Batch"
  defp tx_mod("temporal_sdk_operator"), do: "TemporalSdk.Operator"
  defp tx_mod("temporal_sdk_schedule"), do: "TemporalSdk.Schedule"
  defp tx_mod("temporal_sdk_service"), do: "TemporalSdk.Service"
  defp tx_mod("temporal_sdk_versioning"), do: "TemporalSdk.Versioning"

  defp tx_mod("temporal_sdk_activity"), do: "TemporalSdk.Activity"
  defp tx_mod("temporal_sdk_nexus"), do: "TemporalSdk.Nexus"
  defp tx_mod("temporal_sdk_workflow"), do: "TemporalSdk.Workflow"

  defp tx_mod("temporal_sdk_cluster"), do: "TemporalSdk.Cluster"
  defp tx_mod("temporal_sdk_node"), do: "TemporalSdk.Node"
  defp tx_mod("temporal_sdk_worker"), do: "TemporalSdk.Worker"

  defp tx_mod(mod), do: ":#{mod}"
end
