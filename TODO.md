Add Elixir SDK syntactic wrapper.

Add temporal_sdk_api_workflow_check_default deterministic check module inline with other SDKs behaviour.

Better "temporal_sdk_api_awaitable_index:merge_data/3": merge using `event_id` instead of `state` only.

Update `gun`.

Implement workflow updates and remaining workflow commands.

Gradually add remaining Temporal services commands.

Finalize `start_activity`: session_execution, direct_execution, direct_result.

Workflow query: add conventional handle and special `{query, QueryType}` info handler.

Workflow and activity executor: refactor `handle_failure` to async and safe.

Add old marker value to mutable marker function.

Implement Nexus.

Implement Worker Versioning.

Gradually add documentation.

Implement in-SDK `temporal.api.enums.v1.WorkflowIdConflictPolicy` for child workflows.

Gradually add more `temporal_sdk_samples`:

* suggest_continue_as_new with activities
* bench_activity
* pubsub counter based on process groups
* sharding Temporal
* time skipping mock test
* mock activity test
* event iterator
* limiters
* benchmark dynamic task worker start/terminate
* parallel executions
* telemetry logs, metrics and traces/otel

Activity, workflow and nexus tasks: node_execution.

Asynchronous activity completion by heartbeat.

Testing:

* recover tons of (currently offline) unit tests outdated/invalidated during numerous SDK refactors
* add pending unit tests
* add pending integration tests
* add pending replay tests
* add endpoint load balancing tests

Add heartbeat throttle to activity executor.

Finalize telemetry and metrics, logs and traces.

Activity, workflow and nexus tasks: opentelemetry context.

Add ability to disable telemetry and otel in executors - important during user WF replay.

Add GitHub CI/CD (including ICLA signing automation?).

Migrate currently private API proto generation app to public e-script, integrate with CI/CD.

Add zstd (new in OTP 28) as a compressor to grpc client.

Add Gleam SDK syntactic wrapper if possible.

Move pricing info from repo README to an external project website.
