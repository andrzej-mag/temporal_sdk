defmodule TemporalSdk.Node do
  @moduledoc File.read!("docs/node/-module.md")

  defdelegate stats(), to: :temporal_sdk_node
  defdelegate os_stats(), to: :temporal_sdk_node
  defdelegate os_disk_mounts(), to: :temporal_sdk_node
end
