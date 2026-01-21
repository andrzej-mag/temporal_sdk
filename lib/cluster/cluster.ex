defmodule TemporalSdk.Cluster do
  @external_resource "docs/cluster/-module.md"
  @moduledoc TemporalSdk.Utils.exdoc!("docs/cluster/-module.md")

  @external_resource "docs/cluster/is_started-1.md"
  @doc TemporalSdk.Utils.exdoc!("docs/cluster/is_started-1.md")
  defdelegate is_started(cluster), to: :temporal_sdk_cluster

  @external_resource "docs/cluster/list-0.md"
  @doc TemporalSdk.Utils.exdoc!("docs/cluster/list-0.md")
  defdelegate list(), to: :temporal_sdk_cluster

  @external_resource "docs/cluster/stats-1.md"
  @doc TemporalSdk.Utils.exdoc!("docs/cluster/stats-1.md")
  defdelegate stats(cluster), to: :temporal_sdk_cluster
end
