defmodule TemporalSdk.Activity do
  @moduledoc File.read!("docs/temporal_sdk/activity/module.md")

  defmacro __using__(_opts) do
    quote do
      @behaviour :temporal_sdk_activity

      import TemporalSdk.Activity, warn: false
    end
  end

  defdelegate await_data(ets_pattern), to: :temporal_sdk_activity
  defdelegate await_data(ets_pattern, timeout), to: :temporal_sdk_activity
  defdelegate cancel(canceled_details), to: :temporal_sdk_activity
  defdelegate complete(result), to: :temporal_sdk_activity
  defdelegate fail(application_failure), to: :temporal_sdk_activity
  defdelegate fail(class, reason, stacktrace), to: :temporal_sdk_activity
  defdelegate heartbeat(), to: :temporal_sdk_activity
  defdelegate heartbeat(heartbeat), to: :temporal_sdk_activity
  defdelegate cancel_requested(), to: :temporal_sdk_activity
  defdelegate activity_paused(), to: :temporal_sdk_activity
  defdelegate elapsed_time(), to: :temporal_sdk_activity
  defdelegate elapsed_time(unit), to: :temporal_sdk_activity
  defdelegate remaining_time(), to: :temporal_sdk_activity
  defdelegate remaining_time(unit), to: :temporal_sdk_activity
  defdelegate last_heartbeat(), to: :temporal_sdk_activity
  defdelegate get_data(), to: :temporal_sdk_activity
  defdelegate set_data(task_data), to: :temporal_sdk_activity
end
