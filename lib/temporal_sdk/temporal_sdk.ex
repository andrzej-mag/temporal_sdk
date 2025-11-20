defmodule TemporalSdk do
  @moduledoc """
  Common workflow services module.

  See `m::temporal_sdk`.
  """

  defdelegate start_workflow(cluster, task_queue, workflow_type), to: :temporal_sdk
  defdelegate start_workflow(cluster, task_queue, workflow_type, opts), to: :temporal_sdk

  defdelegate await_workflow(cluster, workflow_execution), to: :temporal_sdk
  defdelegate await_workflow(cluster, workflow_execution, opts), to: :temporal_sdk

  defdelegate wait_workflow(cluster, workflow_execution), to: :temporal_sdk
  defdelegate wait_workflow(cluster, workflow_execution, opts), to: :temporal_sdk

  defdelegate get_workflow_state(cluster, workflow_execution), to: :temporal_sdk
  defdelegate get_workflow_state(cluster, workflow_execution, opts), to: :temporal_sdk

  defdelegate replay_json(cluster, workflow_mod, json), to: :temporal_sdk
  defdelegate replay_json(cluster, workflow_mod, json, opts), to: :temporal_sdk

  defdelegate replay_file(cluster, workflow_mod, filename), to: :temporal_sdk
  defdelegate replay_file(cluster, workflow_mod, filename, opts), to: :temporal_sdk

  defdelegate replay_task(cluster, task_queue, workflow_type, workflow_mod),
    to: :temporal_sdk

  defdelegate replay_task(cluster, task_queue, workflow_type, workflow_mod, opts),
    to: :temporal_sdk

  defdelegate get_workflow_history(cluster, workflow_execution), to: :temporal_sdk
  defdelegate get_workflow_history(cluster, workflow_execution, opts), to: :temporal_sdk
end
