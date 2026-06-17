Temporal workflow task module.

WIP Temporal commands:

* start_activity WIP: session_execution, direct_execution, direct_result

TODO Temporal commands:

* start_nexus/4
* start_nexus/5
* cancel_nexus
* upsert_workflow_search_attributes
* cancel_external_workflow
* signal_external_workflow

## OpenTelemetry

Workflow executions OpenTelemetry tracing is handled internally by the workflow executor state machine
process.
Tracing can be configured when starting a new workflow execution using `temporal_sdk:start_workflow/4`.

Following spans are created for each workflow execution:

* `"StartWorkflow"`: span created with `temporal_sdk:start_workflow/4` command,
* `"RunWorkflow"`: span created after workflow task is polled and execution processing starts,
* `"RunExecution"`: span created for each parallel execution.

Following spans are created for the workflow commands:

* `"StartActvity"`: when activity is started,
* `"StartChildWorkflow"`: when child workflow is started,
* `"StartMarker"` and `"RunMarker"`: when record marker command is executed.
  `"RunMarker"` proceeds `"StartMarker"` span, as marker value must be evaluated before dispatching
  completed workflow task to Temporal server.

By default, spans are enabled for all workflow commands above.
Spans can be disabled for each command by setting the `opentelemetry` command options key to `false`.

Workflow and commands spans and `otel_add_event/2` command are using local worker node time for
OpenTelemetry timestamps.
`"RunWorkflow"` span includes an OpenTelemetry event `"StartWorkflowTask"`, which marks last known history
event created by Temporal server, using (server) event time as a timestamp.

OpenTelemetry traces are propagated using task headers, serialized with the W3C Trace Context standard
via `m:otel_propagator_text_map`.
Spans and OpenTelemetry commands are created and exported only during live workflow execution.
They are suppressed during workflow replay to prevent duplicate entries in the APM backend.

SDK doesn't support custom workflow spans creation, as managing them across workflow executor failures
and replays would be challenging. Each parallel execution starts its own span, this functionality should
be used instead of regular spans.

Following [SDK Samples](https://github.com/andrzej-mag/temporal_sdk_samples) provide OpenTelemetry
traces screenshots:

* [Child Workflow](https://hexdocs.pm/temporal_sdk_samples/child_workflow.html),
* [Hello World](https://hexdocs.pm/temporal_sdk_samples/hello_world.html),
* [Otel Sample](https://hexdocs.pm/temporal_sdk_samples/otel_sample.html),
* [Saga](https://hexdocs.pm/temporal_sdk_samples/saga.html).
