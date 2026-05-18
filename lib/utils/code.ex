defmodule TemporalSdk.Utils.Code do
  @moduledoc false

  @spec delegate_moduledoc(Keyword.t()) :: Macro.t()
  defmacro delegate_moduledoc(opts) do
    {opts, _binding} = Code.eval_quoted(opts, [], __CALLER__)
    from = opts |> Keyword.fetch!(:from) |> String.to_charlist()
    {:ok, forms} = :epp.parse_file(from, [~c"include"], [])
    moduledoc_path = fetch_moduledoc_path(forms)
    moduledoc_text = if moduledoc_path, do: exdoc!(moduledoc_path), else: nil

    quote do
      if unquote(moduledoc_path), do: @external_resource(unquote(moduledoc_path))
      if unquote(moduledoc_text), do: @moduledoc(unquote(moduledoc_text))
    end
  end

  @spec delegate_all(Keyword.t()) :: Macro.t()
  defmacro delegate_all(opts) do
    {opts, _binding} = Code.eval_quoted(opts, [], __CALLER__)
    from = opts |> Keyword.fetch!(:from) |> String.to_charlist()
    {:ok, forms} = :epp.parse_file(from, [~c"include"], [])
    exported_types = fetch_exported_types(forms, [])
    exported_functions = fetch_exported_functions(forms, [])
    {module_path, module_name} = fetch_module(forms)
    moduledoc_path = fetch_moduledoc_path(forms)
    moduledoc_text = if moduledoc_path, do: exdoc!(moduledoc_path), else: nil
    functions = fetch_functions(forms, exported_functions, [])

    module_ast =
      quote do
        if unquote(module_path), do: @external_resource(unquote(module_path))
        if unquote(moduledoc_path), do: @external_resource(unquote(moduledoc_path))
        if unquote(moduledoc_text), do: @moduledoc(unquote(moduledoc_text))
      end

    funtions_ast =
      for {fun_name, args, spec, doc_path, group} <- functions do
        doc = exdoc!(doc_path)
        spec = translate_spec(fun_name, spec, exported_types, module_name)

        quote do
          if unquote(doc_path), do: @external_resource(unquote(doc_path))
          if unquote(group), do: @doc(group: unquote(group))
          if unquote(doc), do: @doc(unquote(doc))
          @spec unquote(spec)
          def unquote(fun_name)(unquote_splicing(args)) do
            unquote(module_name).unquote(fun_name)(unquote_splicing(args))
          end
        end
      end

    quote do
      unquote(module_ast)
      unquote(funtions_ast)
    end
  end

  defp fetch_exported_functions([{:attribute, _, :export, exported} | tforms], acc),
    do: fetch_exported_functions(tforms, Keyword.keys(exported) ++ acc)

  defp fetch_exported_functions([_ | tforms], acc), do: fetch_exported_functions(tforms, acc)
  defp fetch_exported_functions([], acc), do: acc

  defp fetch_module([{:attribute, _, :file, {path, _}}, {:attribute, _, :module, mod} | _]),
    do: {List.to_string(path), mod}

  defp fetch_module(_), do: {nil, nil}

  defp fetch_moduledoc_path([
         _,
         _,
         {:attribute, _, :file, {path, _}},
         {:attribute, _, :moduledoc, _} | _
       ]) do
    do_file_path(path)
  end

  defp fetch_moduledoc_path(_), do: nil

  defp fetch_exported_types(
         [{:attribute, _, :type, _}, {:attribute, _, :export_type, [{type, 0}]} | tforms],
         acc
       ),
       do: fetch_exported_types(tforms, [type | acc])

  defp fetch_exported_types([_ | tforms], acc), do: fetch_exported_types(tforms, acc)
  defp fetch_exported_types([], acc), do: acc

  defp fetch_functions(
         [
           {:attribute, _, :file, {doc_path, _}},
           {:attribute, _, :doc, _},
           {:attribute, _, :file, _},
           {:attribute, _, :doc, %{group: group}},
           {:attribute, _, :spec, spec},
           {:function, _, fun, _arity, [{:clause, _, vars, _, _}]} | tforms
         ],
         exported_functions,
         acc
       ) do
    case Enum.member?(exported_functions, fun) do
      true ->
        fetch_functions(tforms, exported_functions, [
          {fun, do_vars(vars), spec, do_file_path(doc_path), List.to_string(group)} | acc
        ])

      false ->
        fetch_functions(tforms, exported_functions, acc)
    end
  end

  defp fetch_functions(
         [
           {:attribute, _, :doc, %{group: group}},
           {:attribute, _, :file, {doc_path, _}},
           {:attribute, _, :doc, _},
           {:attribute, _, :file, _},
           {:attribute, _, :spec, spec},
           {:function, _, fun, _arity, [{:clause, _, vars, _, _}]} | tforms
         ],
         exported_functions,
         acc
       ) do
    case Enum.member?(exported_functions, fun) do
      true ->
        fetch_functions(tforms, exported_functions, [
          {fun, do_vars(vars), spec, do_file_path(doc_path), List.to_string(group)} | acc
        ])

      false ->
        fetch_functions(tforms, exported_functions, acc)
    end
  end

  defp fetch_functions(
         [
           {:attribute, _, :file, {doc_path, _}},
           {:attribute, _, :doc, _},
           {:attribute, _, :file, _},
           {:attribute, _, :spec, spec},
           {:function, _, fun, _arity, [{:clause, _, vars, _, _}]} | tforms
         ],
         exported_functions,
         acc
       ) do
    case Enum.member?(exported_functions, fun) do
      true ->
        fetch_functions(tforms, exported_functions, [
          {fun, do_vars(vars), spec, do_file_path(doc_path), nil} | acc
        ])

      false ->
        fetch_functions(tforms, exported_functions, acc)
    end
  end

  defp fetch_functions(
         [
           {:attribute, _, :doc, %{group: group}},
           {:attribute, _, :spec, spec},
           {:function, _, fun, _arity, [{:clause, _, vars, _, _}]} | tforms
         ],
         exported_functions,
         acc
       ) do
    case Enum.member?(exported_functions, fun) do
      true ->
        fetch_functions(tforms, exported_functions, [
          {fun, do_vars(vars), spec, nil, List.to_string(group)} | acc
        ])

      false ->
        fetch_functions(tforms, exported_functions, acc)
    end
  end

  defp fetch_functions(
         [
           {:attribute, _, :doc, false},
           {:attribute, _, :spec, _spec},
           {:function, _, _fun, _arity, [{:clause, _, _vars, _, _}]} | tforms
         ],
         exported_functions,
         acc
       ) do
    fetch_functions(tforms, exported_functions, acc)
  end

  defp fetch_functions(
         [
           {:attribute, _, :spec, spec},
           {:function, _, fun, _arity, [{:clause, _, vars, _, _}]} | tforms
         ],
         exported_functions,
         acc
       ) do
    case Enum.member?(exported_functions, fun) do
      true ->
        fetch_functions(tforms, exported_functions, [{fun, do_vars(vars), spec, nil, nil} | acc])

      false ->
        fetch_functions(tforms, exported_functions, acc)
    end
  end

  defp fetch_functions(
         [
           {:attribute, _, :doc, false},
           {:function, _, _fun, _arity, [{:clause, _, _vars, _, _}]} | tforms
         ],
         exported_functions,
         acc
       ) do
    fetch_functions(tforms, exported_functions, acc)
  end

  defp fetch_functions(
         [{:function, _, fun, _arity, [{:clause, _, vars, _, _}]} | tforms],
         exported_functions,
         acc
       ) do
    case Enum.member?(exported_functions, fun) do
      true ->
        fetch_functions(tforms, exported_functions, [{fun, do_vars(vars), nil, nil, nil} | acc])

      false ->
        fetch_functions(tforms, exported_functions, acc)
    end
  end

  defp fetch_functions([_ | tforms], exported_functions, acc),
    do: fetch_functions(tforms, exported_functions, acc)

  defp fetch_functions([], _exported_functions, acc), do: Enum.sort(acc)

  defp do_vars(vars),
    do:
      Enum.map(vars, fn {:var, _, v} ->
        {v |> Atom.to_string() |> Macro.underscore() |> String.to_atom(), [], nil}
      end)

  defp translate_spec(_fun_name, {{name, _arity}, [fun_type]}, exported_types, module_name) do
    {:type, _line, :fun, [{:type, _, :product, args_ast}, return_type_ast]} = fun_type
    elixir_args = Enum.map(args_ast, fn t -> do_type(t, exported_types, module_name) end)
    elixir_return = do_type(return_type_ast, exported_types, module_name)
    {:"::", [], [{name, [], elixir_args}, elixir_return]}
  end

  defp translate_spec(fun_name, nil, _exported_types, _module_name),
    do: raise("Missing specification for exported function: `#{fun_name}`")

  defp do_type({:ann_type, _line, [{:var, _, var_name}, type_ast]}, et, mn) do
    elixir_var_name = var_name |> Atom.to_string() |> Macro.underscore() |> String.to_atom()
    {:"::", [], [{elixir_var_name, [], nil}, do_type(type_ast, et, mn)]}
  end

  defp do_type({:type, _line, :union, types}, et, mn) do
    types
    |> Enum.map(&do_type(&1, et, mn))
    |> Enum.reverse()
    |> Enum.reduce(fn type, acc -> {:|, [], [type, acc]} end)
  end

  defp do_type({:user_type, _line, type_name, args}, exported_types, module_name) do
    elixir_args = Enum.map(args, &do_type(&1, exported_types, module_name))

    case Enum.member?(exported_types, type_name) do
      false -> {type_name, [], elixir_args}
      true -> {{:., [], [module_name, type_name]}, [], elixir_args}
    end
  end

  defp do_type({:remote_type, _line, [{:atom, _, mod}, {:atom, _, type}, args]}, et, mn) do
    elixir_args = Enum.map(args, &do_type(&1, et, mn))
    {{:., [], [mod, type]}, [], elixir_args}
  end

  defp do_type({:type, _line, :tuple, elements}, et, mn) do
    elixir_elements = Enum.map(elements, &do_type(&1, et, mn))
    {:{}, [], elixir_elements}
  end

  defp do_type({:type, _line, :list, [type]}, et, mn), do: [do_type(type, et, mn)]

  defp do_type({:type, _line, :list, [{:type, _, :tuple, [{:atom, _, key}, value_type]}]}, et, mn) do
    [{key, do_type(value_type, et, mn)}]
  end

  defp do_type({:type, _line, :nonempty_list, [type]}, et, mn),
    do: [do_type(type, et, mn), {:..., [], nil}]

  defp do_type({:type, _line, :nonempty_list, []}, _et, _mn),
    do: [{:term, [], []}, {:..., [], nil}]

  defp do_type({:type, _line, :list, []}, _et, _mn), do: [{:any, [], []}]

  defp do_type({:type, _line, :map, :any}, _et, _mn), do: {:map, [], []}

  defp do_type({:type, _line, :map, pairs}, et, mn) do
    elixir_pairs =
      Enum.map(pairs, fn
        {:type, _, :map_field_assoc, [k, v]} -> {do_type(k, et, mn), do_type(v, et, mn)}
        {:type, _, :map_field_exact, [k, v]} -> {do_type(k, et, mn), do_type(v, et, mn)}
      end)

    {:%{}, [], elixir_pairs}
  end

  defp do_type({:type, _line, :string, []}, _et, _mn), do: {:charlist, [], []}

  defp do_type({:type, _line, :nonempty_string, []}, _et, _mn), do: {:nonempty_charlist, [], []}

  # Map explicit Erlang binary types to String.t() if they carry textual context
  defp do_type({:remote_type, _line, [{:atom, _, :erlang}, {:atom, _, :binary}, []]}, _et, _mn),
    do: {{:., [], [{:__aliases__, [], [:String]}, :t]}, [], []}

  defp do_type({:type, _line, :binary, [{:integer, _, _each}, {:integer, _, _unit}]}, _et, _mn) do
    {:bitstring, [], []}
  end

  defp do_type({:type, _line, :fun, []}, _et, _mn), do: {:fun, [], []}

  defp do_type({:type, _line, nil, []}, _et, _mn), do: []

  defp do_type({:type, _line, :any, []}, _et, _mn), do: {:term, [], []}

  defp do_type({:type, _line, type, _}, _, _), do: {type, [], []}

  defp do_type({tag, _line, value}, _, _) when tag in [:atom, :integer, :float], do: value

  defp do_type(other, _, _), do: throw({:unsupported_erlang_type, other})

  defp do_file_path(path),
    do: path |> List.to_string() |> Path.expand() |> Path.relative_to_cwd()

  @spec exdoc!(Path.t() | nil) :: String.t() | nil
  def exdoc!(nil), do: nil
  def exdoc!(erlang_docs_path), do: erlang_docs_path |> File.read!() |> translate_doc()

  def translate_doc(doc_string) do
    doc_string
    |> then(fn doc ->
      Regex.replace(~r/(?<!`)`([^`]+)`(?!`)/, doc, fn _, snippet -> "`#{ts(snippet)}`" end)
    end)
    |> then(fn doc ->
      Regex.replace(
        ~r/\(https:\/\/hexdocs\.pm\/temporal_sdk_samples\/([a-z0-9_]+)\.html\)/,
        doc,
        fn _, segment ->
          "(https://hexdocs.pm/temporal_sdk_samples/#{Macro.camelize(segment)}.html)"
        end
      )
    end)
  end

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
            false ->
              [fmod1 | rest1] = String.split(mod, ":", parts: 2, trim: true)

              case rest1 do
                [] -> tx_mod(fmod1)
                _ -> mod
              end

            true ->
              to_elixir(mod, false)
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
