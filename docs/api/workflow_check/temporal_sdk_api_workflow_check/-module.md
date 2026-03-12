Workflow determinism check behaviour module.

The SDK provides two built-in implementations of the `m:temporal_sdk_api_workflow_check` behaviour:
`temporal_sdk_api_workflow_check_temporal` (default) and `temporal_sdk_api_workflow_check_strict`.

In the `temporal_sdk_api_workflow_check_temporal` implementation, actual and replayed
awaitables pass the determinism check if their *kind* matches.

In the `temporal_sdk_api_workflow_check_strict` implementation, actual and replayed awaitables
pass the determinism check only if their full specifications match - their *kind*, *type*, and
*id*/*name* must all be identical.

See also: [GitHub SDK Samples](https://github.com/andrzej-mag/temporal_sdk_samples) -
[Determinism Check](https://github.com/andrzej-mag/temporal_sdk_samples/blob/main/docs/determinism_check.md).
