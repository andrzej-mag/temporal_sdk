-define(INTEGRATION_TEST, true).

-include("test/include/temporal_sdk_test_asserts.hrl").
-include("test/include/temporal_sdk_test_fixtures_helpers.hrl").
-include("test/include/temporal_sdk_test_fixtures_endpoints.hrl").

-define(CL, temporal_sdk_test_cluster_1).
-define(NS, "temporal_sdk_tests").
-define(TQ,
    temporal_sdk_utils_path:string_path([?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, task_queue])
).
-define(WF_MOD,
    temporal_sdk_utils_path:atom_path([?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, workflow])
).
-define(AV_MOD,
    temporal_sdk_utils_path:atom_path([?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, activity])
).
-define(WF_ID,
    temporal_sdk_utils_path:string_path([?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, workflow])
).
-define(AV_ID,
    temporal_sdk_utils_path:string_path([?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, activity])
).
-define(WF_TQ, ?TQ).
-define(AV_TQ, ?TQ).
-define(WF_WORKER_ID, ?WF_MOD).
-define(AV_WORKER_ID, ?AV_MOD).
-define(WF_EXECUTION_ID, root).
-define(DATA, [<<"binary">>, "string", #{<<"k">> => <<"v">>}, [true, 123, 123.456]]).
-define(DATA_ERL, erlang:term_to_binary(?DATA)).
-define(DATA_JSON, temporal_sdk_utils_unicode:characters_to_binary(json:encode(?DATA))).
-define(DATA_TEXT, temporal_sdk_api:serialize_term(?DATA)).
-define(DATA_BIN, temporal_sdk_utils_unicode:characters_to_binary1(?DATA_TEXT)).

-define(TIMEOUT, 5_000).
-define(TOLERATED_WF_DUPLICATES, 2).

-define(FIXTURE(Configs, TestsList), [
    {setup,
        fun() ->
            Apps = ?SETUP(Config),
            ?debugVal(Apps),
            lists:foreach(
                fun({Fun, Arity}) ->
                    WId = temporal_sdk_utils_path:atom_path([?MODULE, Fun, Arity, workflow]),
                    AId = temporal_sdk_utils_path:atom_path([?MODULE, Fun, Arity, activity]),
                    TQ = temporal_sdk_utils_path:string_path([?MODULE, Fun, Arity, task_queue]),
                    meck:new(WId, [non_strict]),
                    meck:new(AId, [non_strict]),
                    {ok, _} = temporal_sdk_worker:start(?CL, workflow, #{
                        worker_id => WId, namespace => ?NS, task_queue => TQ
                    }),
                    {ok, _} = temporal_sdk_worker:start(?CL, activity, #{
                        worker_id => AId, namespace => ?NS, task_queue => TQ
                    })
                end,
                ?FUNCTIONS_LIST
            ),
            Apps
        end,
        fun(Apps) ->
            lists:foreach(
                fun({Fun, Arity}) ->
                    WId = temporal_sdk_utils_path:atom_path([?MODULE, Fun, Arity, workflow]),
                    AId = temporal_sdk_utils_path:atom_path([?MODULE, Fun, Arity, activity]),
                    meck:unload(WId),
                    meck:unload(AId),
                    ok = temporal_sdk_worker:terminate(?CL, workflow, WId),
                    ok = temporal_sdk_worker:terminate(?CL, activity, AId)
                end,
                ?FUNCTIONS_LIST
            ),
            ?CLEANUP(Apps)
        end,
        {timeout, ?TIMEOUT / 1_000 * 5, TestsList}}
 || Config <- Configs
]).

-define(CONFIGS_INTEGRATION, [
    [
        {clusters, [
            {?CL, [
                {
                    client, #{
                        adapter =>
                            {temporal_sdk_grpc_adapter_gun, [{endpoints, lists:nth(1, ?ENDPOINTS)}]}
                    }
                }
            ]}
        ]}
    ]
]).

-define(FUNCTIONS_LIST,
    lists:filtermap(
        fun
            ({module_info, _}) ->
                false;
            ({test, _}) ->
                false;
            ({Fun, Arity}) ->
                maybe
                    nomatch ?= string:prefix(atom_to_list(Fun), "-"),
                    nomatch ?= string:prefix(string:reverse(atom_to_list(Fun)), "_"),
                    {true, {Fun, Arity}}
                else
                    _ -> false
                end
        end,
        ?MODULE:module_info(functions)
    )
).
