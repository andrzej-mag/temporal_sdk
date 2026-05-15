defmodule TemporalSdk.Activity do
  import TemporalSdk.Utils.Code
  delegate_all(from: "src/temporal_sdk/temporal_sdk_activity.erl")
end
