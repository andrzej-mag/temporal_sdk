%% executor process dictionary keys
-define(PID_KEY, '$__temporal_sdk_executor_pid').
-define(ID_KEY, '$__temporal_sdk_executor_execution_id').
-define(IDX_KEY, '$__temporal_sdk_executor_execution_idx').
-define(API_CTX_KEY, '$__temporal_sdk_executor_api_context').
-define(API_CTX_ACTIVITY_KEY, '$__temporal_sdk_executor_api_context_activity').
-define(OTEL_CTX_ID_KEY, '$__temporal_sdk_executor_otel_context').
-define(HISTORY_TABLE_KEY, '$__temporal_sdk_executor_history_table').
-define(INDEX_TABLE_KEY, '$__temporal_sdk_executor_index_table').
-define(COMMANDS_KEY, '$__temporal_sdk_executor_execution_commands').
-define(AWAIT_COUNTER_KEY, '$__temporal_sdk_executor_await_counter').

-define(MSG_API, '$__temporal_sdk_executor_message_api').
-define(MSG_PRV, '$__temporal_sdk_executor_message_private').
