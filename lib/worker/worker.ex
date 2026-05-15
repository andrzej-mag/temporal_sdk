defmodule TemporalSdk.Worker do
  import TemporalSdk.Utils.Code
  delegate_all(from: "src/worker/temporal_sdk_worker.erl")
end
