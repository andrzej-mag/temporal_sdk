defmodule TemporalSdk.Cluster do
  @moduledoc File.read!("docs/cluster/-module.md")

  defdelegate is_ready(cluster), to: :temporal_sdk_cluster
  defdelegate list(), to: :temporal_sdk_cluster
  defdelegate stats(cluster), to: :temporal_sdk_cluster
end
