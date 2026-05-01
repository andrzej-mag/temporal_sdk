Terminates workflow execution.

Workflow execution termination is a hard stop Temporal command.
After running this command, the SDK is not notified by the Temporal server of the workflow termination.
Consequently, the workflow termination leaves a stale workflow execution task on the worker.
This SDK runs approximately every 60 seconds (when using recommended default settings)
`GetWorkflowExecutionHistoryReverseRequest` gRPC call to monitor workflow execution progress.
If the events history returned in the `GetWorkflowExecutionHistoryReverseResponse` starts with a
`WorkflowExecutionTerminated` event, the workflow executor is terminated with its `closing_state` set
to `terminated`.

In most cases, it is recommended to use the `cancel_workflow/3` command instead.

[SDK Samples](https://github.com/andrzej-mag/temporal_sdk_samples)
[Workflow Terminate](https://github.com/andrzej-mag/temporal_sdk_samples/blob/main/docs/workflow_terminate.md)
demonstrates command use.
