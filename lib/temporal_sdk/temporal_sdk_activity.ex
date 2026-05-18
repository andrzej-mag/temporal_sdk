defmodule TemporalSdk.Activity do
  import TemporalSdk.Utils.Code
  delegate_all(from: "src/temporal_sdk/temporal_sdk_activity.erl")

  defmacro __using__(_opts) do
    quote do
      @behaviour :temporal_sdk_activity

      import TemporalSdk.Activity, warn: false
    end
  end
end
