defmodule TemporalSdk.Cluster do
  @external_resource "docs/cluster/-module.md"
  @moduledoc TemporalSdk.Utils.exdoc!("docs/cluster/-module.md")

  defdelegate is_started(cluster), to: :temporal_sdk_cluster
  defdelegate list(), to: :temporal_sdk_cluster
  defdelegate stats(cluster), to: :temporal_sdk_cluster
end
