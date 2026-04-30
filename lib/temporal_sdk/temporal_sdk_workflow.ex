defmodule TemporalSdk.Workflow do
  @external_resource "docs/temporal_sdk/workflow/-module.md"
  @moduledoc TemporalSdk.Utils.exdoc!("docs/temporal_sdk/workflow/-module.md")

  @delegate_mod :temporal_sdk_workflow

  defmacro __using__(_opts) do
    quote do
      @behaviour :temporal_sdk_workflow

      import TemporalSdk.Workflow, warn: false
    end
  end

  defdelegate start_activity(activity_type, input), to: @delegate_mod
  defdelegate start_activity(activity_type, input, opts), to: @delegate_mod
  defdelegate cancel_activity(activity_or_activity_data), to: @delegate_mod
  defdelegate cancel_activity(activity_or_activity_data, opts), to: @delegate_mod
  defdelegate record_marker(marker_value_fun), to: @delegate_mod
  defdelegate record_marker(marker_value_fun, opts), to: @delegate_mod
  defdelegate start_timer(start_to_fire_timeout), to: @delegate_mod
  defdelegate start_timer(start_to_fire_timeout, opts), to: @delegate_mod
  defdelegate cancel_timer(timer_or_timer_data_or_timer_id), to: @delegate_mod
  defdelegate cancel_timer(timer_or_timer_data_or_timer_id, opts), to: @delegate_mod
  defdelegate start_child_workflow(task_queue, workflow_type), to: @delegate_mod
  defdelegate start_child_workflow(task_queue, workflow_type, opts), to: @delegate_mod
  defdelegate start_nexus(endpoint, service, operation, input), to: @delegate_mod
  defdelegate start_nexus(endpoint, service, operation, input, opts), to: @delegate_mod
  defdelegate modify_workflow_properties(upserted_memo_fields), to: @delegate_mod
  defdelegate modify_workflow_properties(upserted_memo_fields, opts), to: @delegate_mod
  defdelegate complete_workflow_execution(result), to: @delegate_mod
  defdelegate cancel_workflow_execution(details), to: @delegate_mod
  defdelegate fail_workflow_execution(application_failure), to: @delegate_mod
  defdelegate continue_as_new_workflow(task_queue, workflow_type), to: @delegate_mod

  defdelegate continue_as_new_workflow(task_queue, workflow_type, opts),
    to: @delegate_mod

  defdelegate admit_signal(signal_or_signal_name), to: @delegate_mod
  defdelegate admit_signal(signal_or_signal_name, opts), to: @delegate_mod
  defdelegate respond_query(query_type, opts), to: @delegate_mod

  defdelegate record_uuid4(), to: @delegate_mod
  defdelegate record_uuid4(opts), to: @delegate_mod
  defdelegate record_system_time(), to: @delegate_mod
  defdelegate record_system_time(unit_or_opts), to: @delegate_mod
  defdelegate record_system_time(unit, opts), to: @delegate_mod
  defdelegate record_rand_uniform(), to: @delegate_mod
  defdelegate record_rand_uniform(range_or_opts), to: @delegate_mod
  defdelegate record_rand_uniform(range, opts), to: @delegate_mod
  defdelegate record_app_env(par), to: @delegate_mod
  defdelegate record_app_env(par, opts), to: @delegate_mod
  defdelegate record_os_env(var_name), to: @delegate_mod
  defdelegate record_os_env(var_name, opts), to: @delegate_mod

  defdelegate await(await_pattern), to: @delegate_mod
  defdelegate await(await_pattern, timeout), to: @delegate_mod
  defdelegate await_all(await_pattern), to: @delegate_mod
  defdelegate await_all(await_pattern, timeout), to: @delegate_mod
  defdelegate await_any(await_pattern), to: @delegate_mod
  defdelegate await_any(await_pattern, timeout), to: @delegate_mod
  defdelegate await_info(info_or_info_id), to: @delegate_mod

  defdelegate await_info(info_or_info_id, info_timeout, awaitable_timeout),
    to: @delegate_mod

  defdelegate is_awaited(await_pattern), to: @delegate_mod
  defdelegate is_awaited_all(await_pattern), to: @delegate_mod
  defdelegate is_awaited_any(await_pattern), to: @delegate_mod
  defdelegate wait(await_pattern), to: @delegate_mod
  defdelegate wait(await_pattern, timeout), to: @delegate_mod
  defdelegate wait_all(await_pattern), to: @delegate_mod
  defdelegate wait_all(await_pattern, timeout), to: @delegate_mod
  defdelegate wait_any(await_pattern), to: @delegate_mod
  defdelegate wait_any(await_pattern, timeout), to: @delegate_mod
  defdelegate wait_info(info_or_info_id), to: @delegate_mod

  defdelegate wait_info(info_or_info_id, info_timeout, awaitable_timeout),
    to: @delegate_mod

  defdelegate start_execution(function), to: @delegate_mod
  defdelegate start_execution(function, input), to: @delegate_mod
  defdelegate start_execution(function, input, opts), to: @delegate_mod
  defdelegate start_execution(module, function, input, opts), to: @delegate_mod
  defdelegate set_info(info_value), to: @delegate_mod
  defdelegate set_info(info_value, opts), to: @delegate_mod
  defdelegate workflow_info(), to: @delegate_mod
  defdelegate get_workflow_result(), to: @delegate_mod
  defdelegate set_workflow_result(workflow_result), to: @delegate_mod
  defdelegate await_open_before_close(is_enabled), to: @delegate_mod

  @external_resource "docs/temporal_sdk/workflow/evict_workflow-0.md"
  @doc TemporalSdk.Utils.exdoc!("docs/temporal_sdk/workflow/evict_workflow-0.md")
  defdelegate evict_workflow(), to: @delegate_mod

  defdelegate terminate_executor(), to: @delegate_mod
  defdelegate terminate_executor(reason), to: @delegate_mod

  defdelegate select_index(pattern_or_spec_or_continuation), to: @delegate_mod
  defdelegate select_index(index_pattern_spec, limit), to: @delegate_mod

  defdelegate select_history(event_id_or_pattern_or_spec_or_continuation),
    to: @delegate_mod

  defdelegate select_history(history_pattern_spec, limit), to: @delegate_mod
end
