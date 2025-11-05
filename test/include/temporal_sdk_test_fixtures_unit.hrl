-include("test/include/temporal_sdk_test_asserts.hrl").
-include("test/include/temporal_sdk_test_fixtures_helpers.hrl").
-include("test/include/temporal_sdk_test_fixtures_endpoints.hrl").
-include("test/include/temporal_sdk_test_fixtures_unit_configs.hrl").

-define(NAMESPACE, "temporal_sdk_tests").
-define(TASK_QUEUE_NAME, "test_task_queue_name").
-define(WORKER_ID, 'temporal_sdk_tests/test_task_queue_name').
%% equivalent to:
%% -define(WORKER_ID, temporal_sdk_utils_path:atom_path([?NAMESPACE, ?TASK_QUEUE_NAME])).

-define(FIXTURE(Configs, TestsList), [
    {setup, fun() -> ?SETUP(Config) end, fun(Apps) -> ?CLEANUP(Apps) end,
        {with, {proplists:get_keys(proplists:get_value(clusters, Config)), Config}, TestsList}}
 || Config <- Configs
]).
