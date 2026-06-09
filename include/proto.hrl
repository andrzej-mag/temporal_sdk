-define(TEMPORAL_SPEC, temporal_sdk_proto_service_workflow_binaries).
-define(TEMPORAL_SPEC_OPERATOR, temporal_sdk_proto_service_operator_binaries).
%% Alternative:
%% -define(TEMPORAL_SPEC, temporal_sdk_proto_service_workflow_strings).
%% -define(TEMPORAL_SPEC_OPERATOR, temporal_sdk_proto_service_operator_strings).

%% -------------------------------------------------------------------------------------------------
%% Temporal API Erlang SDK extensions

-define(TASK_HEADER_KEY_SDK_DATA, "sdk_data").
-define(TASK_HEADER_KEY_SDK_DATA_BIN, ~"sdk_data").
-define(TASK_HEADER_KEY_OTEL_TRACE, "_tracer-data").
-define(TASK_HEADER_KEY_OTEL_TRACE_BIN, ~"_tracer-data").
-define(MUTATION_RESET_PREFIX, "sdk_mutation").
-define(AWAIT_TIMEOUT_ID, "sdk_timeout").
-define(DEFAULT_MARKER_TYPE, none).
