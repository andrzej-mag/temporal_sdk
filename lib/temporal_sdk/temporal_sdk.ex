defmodule TemporalSdk do
  @external_resource "docs/temporal_sdk/-module.md"
  @moduledoc TemporalSdk.Utils.exdoc!("docs/temporal_sdk/-module.md")

  @delegate_mod :temporal_sdk

  @doc group: "Workflow commands"
  defdelegate start_workflow(cluster, task_queue, workflow_type), to: @delegate_mod
  @doc group: "Workflow commands"
  defdelegate start_workflow(cluster, task_queue, workflow_type, opts), to: @delegate_mod

  @doc group: "Workflow commands"
  defdelegate await_workflow(cluster, workflow_execution), to: @delegate_mod
  @doc group: "Workflow commands"
  defdelegate await_workflow(cluster, workflow_execution, opts), to: @delegate_mod

  @doc group: "Workflow commands"
  defdelegate wait_workflow(cluster, workflow_execution), to: @delegate_mod
  @doc group: "Workflow commands"
  defdelegate wait_workflow(cluster, workflow_execution, opts), to: @delegate_mod

  @doc group: "Workflow commands"
  defdelegate describe_workflow(cluster, workflow_execution), to: @delegate_mod
  @doc group: "Workflow commands"
  defdelegate describe_workflow(cluster, workflow_execution, opts), to: @delegate_mod

  @doc group: "Workflow commands"
  defdelegate get_workflow_state(cluster, workflow_execution), to: @delegate_mod
  @doc group: "Workflow commands"
  defdelegate get_workflow_state(cluster, workflow_execution, opts), to: @delegate_mod

  @doc group: "Workflow commands"
  defdelegate get_workflow_history(cluster, workflow_execution), to: @delegate_mod
  @doc group: "Workflow commands"
  defdelegate get_workflow_history(cluster, workflow_execution, opts), to: @delegate_mod

  @doc group: "Workflow commands"
  defdelegate cancel_workflow(cluster, workflow_execution), to: @delegate_mod
  @doc group: "Workflow commands"
  defdelegate cancel_workflow(cluster, workflow_execution, opts), to: @delegate_mod

  @doc group: "Workflow commands"
  defdelegate query_workflow(cluster, workflow_execution, query_type), to: @delegate_mod

  @doc group: "Workflow commands"
  defdelegate query_workflow(cluster, workflow_execution, query_type, opts),
    to: @delegate_mod

  @doc group: "Workflow commands"
  defdelegate reset_workflow(cluster, workflow_execution), to: @delegate_mod
  @doc group: "Workflow commands"
  defdelegate reset_workflow(cluster, workflow_execution, opts), to: @delegate_mod

  @doc group: "Workflow commands"
  defdelegate signal_workflow(cluster, workflow_execution, signal_name), to: @delegate_mod

  @doc group: "Workflow commands"
  defdelegate signal_workflow(cluster, workflow_execution, signal_name, opts),
    to: @delegate_mod

  @doc group: "Workflow commands"
  defdelegate update_workflow(cluster, workflow_execution, name, opts), to: @delegate_mod

  @doc group: "Utility functions"
  defdelegate replay_json(cluster, workflow_mod, json), to: @delegate_mod
  @doc group: "Utility functions"
  defdelegate replay_json(cluster, workflow_mod, json, opts), to: @delegate_mod

  @doc group: "Utility functions"
  defdelegate replay_file(cluster, workflow_mod, filename), to: @delegate_mod
  @doc group: "Utility functions"
  defdelegate replay_file(cluster, workflow_mod, filename, opts), to: @delegate_mod

  @doc group: "Utility functions"
  defdelegate replay_task(cluster, task_queue, workflow_type, workflow_mod),
    to: @delegate_mod

  @doc group: "Utility functions"
  defdelegate replay_task(cluster, task_queue, workflow_type, workflow_mod, opts),
    to: @delegate_mod

  @doc group: "Utility functions"
  defdelegate format_response(cluster, message_name, response), to: @delegate_mod
end
