defmodule TemporalSdk.Workflow do
  @moduledoc """
  Temporal workflow task module.

  See `m::temporal_sdk_workflow`.
  """

  defmacro __using__(_opts) do
    quote do
      @behaviour :temporal_sdk_workflow

      import TemporalSdk.Workflow, warn: false
    end
  end

  defdelegate start_activity(activity_type, input), to: :temporal_sdk_workflow
  defdelegate start_activity(activity_type, input, opts), to: :temporal_sdk_workflow
  defdelegate cancel_activity(activity_or_activity_data), to: :temporal_sdk_workflow
  defdelegate cancel_activity(activity_or_activity_data, opts), to: :temporal_sdk_workflow
  defdelegate record_marker(marker_value_fun), to: :temporal_sdk_workflow
  defdelegate record_marker(marker_value_fun, opts), to: :temporal_sdk_workflow
  defdelegate start_timer(start_to_fire_timeout), to: :temporal_sdk_workflow
  defdelegate start_timer(start_to_fire_timeout, opts), to: :temporal_sdk_workflow
  defdelegate cancel_timer(timer_or_timer_data_or_timer_id), to: :temporal_sdk_workflow
  defdelegate cancel_timer(timer_or_timer_data_or_timer_id, opts), to: :temporal_sdk_workflow
  defdelegate start_child_workflow(task_queue, workflow_type), to: :temporal_sdk_workflow
  defdelegate start_child_workflow(task_queue, workflow_type, opts), to: :temporal_sdk_workflow
  defdelegate start_nexus(endpoint, service, operation, input), to: :temporal_sdk_workflow
  defdelegate start_nexus(endpoint, service, operation, input, opts), to: :temporal_sdk_workflow
  defdelegate modify_workflow_properties(upserted_memo_fields), to: :temporal_sdk_workflow
  defdelegate modify_workflow_properties(upserted_memo_fields, opts), to: :temporal_sdk_workflow
  defdelegate complete_workflow_execution(result), to: :temporal_sdk_workflow
  defdelegate cancel_workflow_execution(details), to: :temporal_sdk_workflow
  defdelegate fail_workflow_execution(application_failure), to: :temporal_sdk_workflow
  defdelegate continue_as_new_workflow(task_queue, workflow_type), to: :temporal_sdk_workflow

  defdelegate continue_as_new_workflow(task_queue, workflow_type, opts),
    to: :temporal_sdk_workflow

  defdelegate admit_signal(signal_or_signal_name), to: :temporal_sdk_workflow
  defdelegate admit_signal(signal_or_signal_name, opts), to: :temporal_sdk_workflow
  defdelegate respond_query(query_type, opts), to: :temporal_sdk_workflow
  defdelegate record_uuid4(), to: :temporal_sdk_workflow
  defdelegate record_uuid4(opts), to: :temporal_sdk_workflow
  defdelegate record_system_time(), to: :temporal_sdk_workflow
  defdelegate record_system_time(unit_or_opts), to: :temporal_sdk_workflow
  defdelegate record_system_time(unit, opts), to: :temporal_sdk_workflow
  defdelegate record_rand_uniform(), to: :temporal_sdk_workflow
  defdelegate record_rand_uniform(range_or_opts), to: :temporal_sdk_workflow
  defdelegate record_rand_uniform(range, opts), to: :temporal_sdk_workflow
  defdelegate record_env(par, opts), to: :temporal_sdk_workflow
  defdelegate await(await_pattern), to: :temporal_sdk_workflow
  defdelegate await(await_pattern, timeout), to: :temporal_sdk_workflow
  defdelegate await_one(await_pattern), to: :temporal_sdk_workflow
  defdelegate await_one(await_pattern, timeout), to: :temporal_sdk_workflow
  defdelegate await_all(await_pattern), to: :temporal_sdk_workflow
  defdelegate await_all(await_pattern, timeout), to: :temporal_sdk_workflow
  defdelegate await_info(info_or_info_id), to: :temporal_sdk_workflow

  defdelegate await_info(info_or_info_id, info_timeout, awaitable_timeout),
    to: :temporal_sdk_workflow

  defdelegate is_awaited(await_pattern), to: :temporal_sdk_workflow
  defdelegate is_awaited_one(await_pattern), to: :temporal_sdk_workflow
  defdelegate is_awaited_all(await_pattern), to: :temporal_sdk_workflow
  defdelegate wait(await_pattern), to: :temporal_sdk_workflow
  defdelegate wait(await_pattern, timeout), to: :temporal_sdk_workflow
  defdelegate wait_one(await_pattern), to: :temporal_sdk_workflow
  defdelegate wait_one(await_pattern, timeout), to: :temporal_sdk_workflow
  defdelegate wait_all(await_pattern), to: :temporal_sdk_workflow
  defdelegate wait_all(await_pattern, timeout), to: :temporal_sdk_workflow
  defdelegate wait_info(info_or_info_id), to: :temporal_sdk_workflow

  defdelegate wait_info(info_or_info_id, info_timeout, awaitable_timeout),
    to: :temporal_sdk_workflow

  defdelegate start_execution(function), to: :temporal_sdk_workflow
  defdelegate start_execution(function, input), to: :temporal_sdk_workflow
  defdelegate start_execution(function, input, opts), to: :temporal_sdk_workflow
  defdelegate start_execution(module, function, input, opts), to: :temporal_sdk_workflow
  defdelegate set_info(info_value), to: :temporal_sdk_workflow
  defdelegate set_info(info_value, opts), to: :temporal_sdk_workflow
  defdelegate workflow_info(), to: :temporal_sdk_workflow
  defdelegate get_workflow_result(), to: :temporal_sdk_workflow
  defdelegate set_workflow_result(workflow_result), to: :temporal_sdk_workflow
  defdelegate stop(), to: :temporal_sdk_workflow
  defdelegate stop(reason), to: :temporal_sdk_workflow
  defdelegate await_open_before_close(is_enabled), to: :temporal_sdk_workflow
  defdelegate select_index(pattern_or_spec_or_continuation), to: :temporal_sdk_workflow
  defdelegate select_index(index_pattern_spec, limit), to: :temporal_sdk_workflow

  defdelegate select_history(event_id_or_pattern_or_spec_or_continuation),
    to: :temporal_sdk_workflow

  defdelegate select_history(history_pattern_spec, limit), to: :temporal_sdk_workflow
end
