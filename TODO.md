Finalize telemetry.

Implement workflow execution eviction.

Rename temporal_sdk_workflow await/wait "one" to "any".

Update `gun` version.

Implement workflow updates and remaining workflow commands.

Gradually add remaining Temporal services commands.

Finalize workflow command `start_activity`: session_execution, direct_execution, direct_result.

Workflow query: add conventional handle and special `{query, QueryType}` info handler.

Workflow and activity executor: refactor `handle_failure` to async and safe.

Add old marker value to mutable marker function.

Implement Worker Versioning.

Implement Nexus.

Implement standalone activities.

Activity, workflow and nexus tasks: node_execution.

Asynchronous activity completion by heartbeat.

Add heartbeat throttle to activity executor.

Implement workflow flow opentelemetry tracing.

Add temporal_sdk_prometheus/otel metrics repository.

Add GitHub CI/CD (including ICLA signing automation?).

Migrate currently private API proto generation app to public e-script, integrate with CI/CD.

Add zstd (new in OTP 28) as a compressor to grpc client if zstd supported by Temporal server.

Add Gleam SDK syntactic wrapper if possible.

Unit testing:

* recover tons of (currently offline) unit tests outdated/invalidated during numerous SDK refactors
* add pending unit tests, including Elixir
* add pending integration tests
* add pending replay tests
* add endpoint load balancing tests

Move pricing info from repository README to an external project website.
