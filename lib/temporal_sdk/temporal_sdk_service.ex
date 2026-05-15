defmodule TemporalSdk.Service do
  import TemporalSdk.Utils.Code
  delegate_all(from: "src/temporal_sdk/temporal_sdk_service.erl")
end
