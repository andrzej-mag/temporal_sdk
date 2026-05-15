defmodule TemporalSdk.Node do
  import TemporalSdk.Utils.Code
  delegate_all(from: "src/node/temporal_sdk_node.erl")
end
