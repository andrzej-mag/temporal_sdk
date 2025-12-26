Task worker module.

The task worker is a supervised group of processes that manages processing of the Temporal task
executions. Temporal task executions are managed by the Temporal service.
Task worker processes are supervised by the SDK cluster supervisor.

Task worker responsibilities:

- configure and start the task worker statistics telemetry poller,
- configure worker-level fixed window rate limiter time windows,
- configure worker-level options, such as worker Temporal `namespace`,
- configure Temporal task poller rate limiter,
- configure, start and supervise Temporal task poller,
- configure and enforce rate limiters limits,
- setup and spawn task executors for Temporal task executions polled by the task pollers.

### Task Worker Configuration
