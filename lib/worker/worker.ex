defmodule TemporalSdk.Worker do
  @moduledoc File.read!("docs/worker/-module.md")

  defdelegate count(cluster, worker_type), to: :temporal_sdk_worker
  defdelegate is_alive(cluster, worker_type, worker_id), to: :temporal_sdk_worker
  defdelegate list(cluster, worker_type), to: :temporal_sdk_worker
  defdelegate options(cluster, worker_type, worker_id), to: :temporal_sdk_worker
  defdelegate stats(cluster, worker_type, worker_id), to: :temporal_sdk_worker
  defdelegate get_limits(cluster, worker_type, worker_id), to: :temporal_sdk_worker
  defdelegate set_limits(cluster, worker_type, worker_id, limits), to: :temporal_sdk_worker
  defdelegate set_limits(cluster, worker_type, worker_id, limits, nodes), to: :temporal_sdk_worker
  defdelegate start(cluster, worker_type, worker_opts), to: :temporal_sdk_worker
  defdelegate start(cluster, worker_type, worker_opts, nodes), to: :temporal_sdk_worker
  defdelegate terminate(cluster, worker_type, worker_id), to: :temporal_sdk_worker
  defdelegate terminate(cluster, worker_type, worker_id, nodes), to: :temporal_sdk_worker
end
