Requests workflow eviction on next workflow task completion request.

[SDK Architecture - Workflow Eviction](architecture.md#workflow-eviction) section provides details
about workflow eviction mechanism.

Duplicate eviction requests within the same workflow task cycle are ignored.
Eviction requests are ignored during workflow replay.

[SDK Samples](https://github.com/andrzej-mag/temporal_sdk_samples)
[Eviction Parallel Handler](https://hexdocs.pm/temporal_sdk_samples/eviction_parallel_handler.html) sample demonstrates function usage.
