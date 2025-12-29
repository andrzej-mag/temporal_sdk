SDK cluster configuration and management module.

The SDK cluster is a supervised group of processes that facilitates SDK API interaction with the
(clustered) Temporal service Temporal server(s).
Interaction includes handling gRPC Temporal API services, polling, and processing Temporal task executions.
SDK cluster supervisor is supervised by the SDK node supervisor.

SDK cluster responsibilities:

- configure and start the SDK cluster statistics telemetry poller,
- configure SDK cluster-level fixed window rate limiter time windows,
- configure SDK cluster-wide options, such as `workflow_scope`,
- configure, start and supervise the gRPC client connections pool connecting to the Temporal server(s),
- configure, start and supervise task worker processes.

## SDK Cluster Configuration
