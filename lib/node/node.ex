defmodule TemporalSdk.Node do
  @external_resource "docs/node/-module.md"
  @moduledoc TemporalSdk.Utils.exdoc!("docs/node/-module.md")

  @external_resource "docs/node/stats-0.md"
  @doc TemporalSdk.Utils.exdoc!("docs/node/stats-0.md")
  defdelegate stats(), to: :temporal_sdk_node

  @external_resource "docs/node/os_stats-0.md"
  @doc TemporalSdk.Utils.exdoc!("docs/node/os_stats-0.md")
  defdelegate os_stats(), to: :temporal_sdk_node

  @external_resource "docs/node/os_disk_mounts-0.md"
  @doc TemporalSdk.Utils.exdoc!("docs/node/os_disk_mounts-0.md")
  defdelegate os_disk_mounts(), to: :temporal_sdk_node
end
