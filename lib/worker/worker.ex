defmodule TemporalSdk.Worker do
  @moduledoc File.read!("docs/worker/-module.md")

  defdelegate count(cluster, worker_type), to: :temporal_sdk_worker
  defdelegate is_alive(cluster, worker_type, worker_id), to: :temporal_sdk_worker
  defdelegate list(cluster, worker_type), to: :temporal_sdk_worker
  defdelegate options(cluster, worker_type, worker_id), to: :temporal_sdk_worker
  defdelegate stats(cluster, worker_type, worker_id), to: :temporal_sdk_worker

  @doc File.read!("docs/worker/get_limiter_config-3.md")
  defdelegate get_limiter_config(cluster, worker_type, worker_id), to: :temporal_sdk_worker

  @doc File.read!("docs/worker/set_limiter_config-4.md")
  defdelegate set_limiter_config(cluster, worker_type, worker_id, new_limiter_config),
    to: :temporal_sdk_worker

  @doc File.read!("docs/worker/set_limiter_config-5.md")
  defdelegate set_limiter_config(cluster, worker_type, worker_id, new_limiter_config, nodes),
    to: :temporal_sdk_worker

  defdelegate start(cluster, worker_type, worker_opts), to: :temporal_sdk_worker
  defdelegate start(cluster, worker_type, worker_opts, nodes), to: :temporal_sdk_worker
  defdelegate terminate(cluster, worker_type, worker_id), to: :temporal_sdk_worker
  defdelegate terminate(cluster, worker_type, worker_id, nodes), to: :temporal_sdk_worker
end
