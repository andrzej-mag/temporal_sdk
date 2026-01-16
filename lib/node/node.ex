defmodule TemporalSdk.Node do
  @external_resource "docs/node/-module.md"
  @moduledoc File.read!("docs/node/-module.md")

  @external_resource "docs/node/stats-0.md"
  @doc File.read!("docs/node/stats-0.md")
  defdelegate stats(), to: :temporal_sdk_node

  @external_resource "docs/node/os_stats-0.md"
  @doc File.read!("docs/node/os_stats-0.md")
  defdelegate os_stats(), to: :temporal_sdk_node

  @external_resource "docs/node/os_disk_mounts-0.md"
  @doc File.read!("docs/node/os_disk_mounts-0.md")
  defdelegate os_disk_mounts(), to: :temporal_sdk_node
end
