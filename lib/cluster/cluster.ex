defmodule TemporalSdk.Cluster do
  import TemporalSdk.Utils.Code
  delegate_all(from: "src/cluster/temporal_sdk_cluster.erl")
end
