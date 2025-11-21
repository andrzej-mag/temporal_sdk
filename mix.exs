defmodule TemporalSdk.MixProject do
  use Mix.Project

  @source_url "https://github.com/andrzej-mag/temporal_sdk"

  @elixir_deps [
    {:dialyxir, "~> 1.4.0", only: [:dev, :test], runtime: false},
    {:ex_doc, "~> 0.39.0", only: :dev, runtime: false}
  ]

  @shared_deps_opts [
    {:uuid, hex: :uuid_erl}
  ]

  def project,
    do: [
      app: app_name!(),
      version: version(),
      elixir: "~> 1.17",
      deps: deps(@elixir_deps, @shared_deps_opts),
      erlc_options: rebar_key!(:erl_opts),
      test_paths: ["test_ex"],
      deps_path: "_deps",
      # hex.pm package metadata
      description: app_key!(:description) |> to_string,
      name: app_name!(),
      source_url: @source_url,
      package: package(),
      docs: docs()
    ]

  def application,
    do: [
      extra_applications: [:logger, :os_mon],
      mod: app_key!(:mod)
    ]

  defp version, do: app_key!(:vsn) |> to_string

  defp package,
    do: [
      licenses: ["BUSL-1.1"],
      links: %{"GitHub" => @source_url},
      files: ["include", "src", "rebar.config", "LICENSE*", "README*", "lib", "mix.exs"]
    ]

  defp docs,
    do: [
      output: "_doc",
      extras: ["guides/quick_start.md"],
      main: "quick_start",
      source_url: @source_url,
      source_ref: "v#{version()}",
      formatters: ["html"],
      api_reference: false,
      extra_section: "GUIDES",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_modules: groups_for_modules()
    ]

  defp groups_for_modules,
    do: [
      "Services (Elixir)": [
        TemporalSdk,
        TemporalSdk.Batch,
        TemporalSdk.Operator,
        TemporalSdk.Schedule,
        TemporalSdk.Service,
        TemporalSdk.Versioning
      ],
      "Services (Erlang)": [
        :temporal_sdk,
        :temporal_sdk_batch,
        :temporal_sdk_operator,
        :temporal_sdk_schedule,
        :temporal_sdk_service,
        :temporal_sdk_versioning
      ],
      "Tasks (Elixir)": [
        TemporalSdk.Activity,
        TemporalSdk.Nexus,
        TemporalSdk.Workflow
      ],
      "Tasks (Erlang)": [
        :temporal_sdk_activity,
        :temporal_sdk_nexus,
        :temporal_sdk_workflow
      ],
      "Operations (Elixir)": [
        TemporalSdk.Cluster,
        TemporalSdk.Node,
        TemporalSdk.Worker
      ],
      "Operations (Erlang)": [
        :temporal_sdk_cluster,
        :temporal_sdk_limiter,
        :temporal_sdk_node,
        :temporal_sdk_worker
      ],
      Telemetry: [
        :temporal_sdk_telemetry,
        :temporal_sdk_telemetry_logs,
        :temporal_sdk_telemetry_metrics,
        :temporal_sdk_telemetry_traces
      ],
      API: [
        :temporal_sdk_api,
        :temporal_sdk_api_workflow_check,
        :temporal_sdk_api_workflow_check_strict
      ],
      "gRPC protocol": [
        :temporal_sdk_codec_payload,
        :temporal_sdk_proto,
        :temporal_sdk_proto_service_operator_binaries,
        :temporal_sdk_proto_service_operator_strings,
        :temporal_sdk_proto_service_workflow_binaries,
        :temporal_sdk_proto_service_workflow_strings
      ],
      "gRPC client": [
        :temporal_sdk_client,
        :temporal_sdk_grpc,
        :temporal_sdk_grpc_adapter,
        :temporal_sdk_grpc_adapter_gun,
        :temporal_sdk_grpc_adapter_gun_pool,
        :temporal_sdk_grpc_codec,
        :temporal_sdk_grpc_compressor,
        :temporal_sdk_grpc_converter,
        :temporal_sdk_grpc_interceptor
      ]
    ]

  # -------------------------------------------------------------------------------------------------
  # Erlang config helpers

  defp rebar_config! do
    {:ok, rebar_config} = :file.consult("rebar.config")
    rebar_config
  end

  defp rebar_key!(key), do: Keyword.fetch!(rebar_config!(), key)

  defp app_src! do
    {:ok, [{:application, name, meta}]} = :file.consult("src/temporal_sdk.app.src")
    {name, meta}
  end

  defp app_key!(key) do
    {_name, meta} = app_src!()
    Keyword.fetch!(meta, key)
  end

  defp app_name! do
    {name, _meta} = app_src!()
    name
  end

  defp deps(elixir_deps, shared_deps_opts) do
    map_fun =
      fn
        {dep, ver} ->
          case Keyword.fetch(shared_deps_opts, dep) do
            {:ok, ex_opts} -> {dep, to_string(ver), ex_opts}
            :error -> {dep, to_string(ver)}
          end

        {dep, ver, opts} ->
          case Keyword.fetch(shared_deps_opts, dep) do
            {:ok, ex_opts} -> {dep, to_string(ver), ex_opts}
            :error -> {dep, to_string(ver), opts}
          end
      end

    rebar_key!(:deps)
    |> Enum.map(map_fun)
    |> Enum.concat(elixir_deps)
  end
end
