defmodule TemporalSdk.Node do
  @moduledoc File.read!("docs/node/-module.md")

  @doc File.read!("docs/node/stats-0.md")
  defdelegate stats(), to: :temporal_sdk_node

  @doc File.read!("docs/node/os_stats-0.md")
  defdelegate os_stats(), to: :temporal_sdk_node

  @doc File.read!("docs/node/os_disk_mounts-0.md")
  defdelegate os_disk_mounts(), to: :temporal_sdk_node
end
