defmodule TemporalSdk.Activity do
  @external_resource "docs/temporal_sdk/activity/-module.md"
  @moduledoc TemporalSdk.Utils.exdoc!("docs/temporal_sdk/activity/-module.md")

  @delegate_mod :temporal_sdk_activity

  defmacro __using__(_opts) do
    quote do
      @behaviour :temporal_sdk_activity

      import TemporalSdk.Activity, warn: false
    end
  end

  defdelegate await_data(ets_pattern), to: @delegate_mod
  defdelegate await_data(ets_pattern, timeout), to: @delegate_mod
  defdelegate cancel(canceled_details), to: @delegate_mod
  defdelegate complete(result), to: @delegate_mod
  defdelegate fail(application_failure), to: @delegate_mod
  defdelegate fail(class, reason, stacktrace), to: @delegate_mod
  defdelegate heartbeat(), to: @delegate_mod
  defdelegate heartbeat(heartbeat), to: @delegate_mod
  defdelegate cancel_requested(), to: @delegate_mod
  defdelegate activity_paused(), to: @delegate_mod
  defdelegate elapsed_time(), to: @delegate_mod
  defdelegate elapsed_time(unit), to: @delegate_mod
  defdelegate remaining_time(), to: @delegate_mod
  defdelegate remaining_time(unit), to: @delegate_mod
  defdelegate last_heartbeat(), to: @delegate_mod
  defdelegate get_data(), to: @delegate_mod
  defdelegate set_data(task_data), to: @delegate_mod
end
