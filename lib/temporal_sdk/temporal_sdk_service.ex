defmodule TemporalSdk.Service do
  @moduledoc File.read!("docs/temporal_sdk/service/-module.md")

  defdelegate get_workflow_history(cluster, workflow_execution), to: :temporal_sdk_service
  defdelegate get_workflow_history(cluster, workflow_execution, opts), to: :temporal_sdk_service
  defdelegate get_workflow_history_reverse(cluster, workflow_execution), to: :temporal_sdk_service

  defdelegate get_workflow_history_reverse(cluster, workflow_execution, opts),
    to: :temporal_sdk_service

  defdelegate describe_workflow(cluster, workflow_execution), to: :temporal_sdk_service
  defdelegate describe_workflow(cluster, workflow_execution, opts), to: :temporal_sdk_service

  defdelegate list_open_workflows(cluster), to: :temporal_sdk_service
  defdelegate list_open_workflows(cluster, opts), to: :temporal_sdk_service

  defdelegate list_closed_workflows(cluster), to: :temporal_sdk_service
  defdelegate list_closed_workflows(cluster, opts), to: :temporal_sdk_service

  defdelegate list_workflows(cluster), to: :temporal_sdk_service
  defdelegate list_workflows(cluster, opts), to: :temporal_sdk_service

  defdelegate list_archived_workflows(cluster), to: :temporal_sdk_service
  defdelegate list_archived_workflows(cluster, opts), to: :temporal_sdk_service

  defdelegate signal_workflow(cluster, workflow_execution, signal_name), to: :temporal_sdk_service

  defdelegate signal_workflow(cluster, workflow_execution, signal_name, opts),
    to: :temporal_sdk_service

  defdelegate query_workflow(cluster, workflow_execution, query_type), to: :temporal_sdk_service

  defdelegate query_workflow(cluster, workflow_execution, query_type, opts),
    to: :temporal_sdk_service

  defdelegate update_workflow(cluster, workflow_execution, name, opts), to: :temporal_sdk_service
end
