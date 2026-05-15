defmodule TemporalSdk.Workflow do
  import TemporalSdk.Utils.Code
  delegate_all(from: "src/temporal_sdk/temporal_sdk_workflow.erl")

  defmacro __using__(_opts) do
    quote do
      @behaviour :temporal_sdk_workflow

      import TemporalSdk.Workflow, warn: false
    end
  end
end
