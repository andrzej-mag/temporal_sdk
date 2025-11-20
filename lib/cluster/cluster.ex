defmodule TemporalSdk.Cluster do
  @moduledoc File.read!("docs/cluster/cluster/-module.md")

  defdelegate is_alive(cluster), to: :temporal_sdk_cluster
  defdelegate list(), to: :temporal_sdk_cluster
  defdelegate stats(cluster), to: :temporal_sdk_cluster
end
