defmodule TemporalSdk.Service do
  @external_resource "docs/temporal_sdk/service/-module.md"
  @moduledoc TemporalSdk.Utils.exdoc!("docs/temporal_sdk/service/-module.md")

  @delegate_mod :temporal_sdk_service

  defdelegate get_workflow_history(cluster, workflow_execution_or_id), to: @delegate_mod
  defdelegate get_workflow_history(cluster, workflow_execution_or_id, opts), to: @delegate_mod
  defdelegate get_workflow_history_reverse(cluster, workflow_execution_or_id), to: @delegate_mod

  defdelegate get_workflow_history_reverse(cluster, workflow_execution_or_id, opts),
    to: @delegate_mod

  defdelegate list_open_workflows(cluster), to: @delegate_mod
  defdelegate list_open_workflows(cluster, opts), to: @delegate_mod

  defdelegate list_closed_workflows(cluster), to: @delegate_mod
  defdelegate list_closed_workflows(cluster, opts), to: @delegate_mod

  defdelegate list_workflows(cluster), to: @delegate_mod
  defdelegate list_workflows(cluster, opts), to: @delegate_mod

  defdelegate list_archived_workflows(cluster), to: @delegate_mod
  defdelegate list_archived_workflows(cluster, opts), to: @delegate_mod
end
