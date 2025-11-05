-export([execute/2]).

-define(CL, test_replay_cluster).
-define(NS, "temporal_sdk_tests").
-define(TQ, "test_replay").
-define(WF_TYPE, test_replay_workflow).
-define(A_TYPE, test_replay_activity).
-define(BASE_DIR, "test_replay").
-define(LOOP_SIZE, 50).
-define(DATA, ["string", <<"binary">>, 123, 1.23, true]).

-include("workflow.hrl").
-include("test/include/temporal_sdk_test_fixtures_helpers.hrl").
-include("test/include/temporal_sdk_test_helpers.hrl").
-include("test_replay/include/temporal_sdk_test_replay_asserts.hrl").

-define(THROW_ON_REPLAY,
    case IsReplaying of
        false -> throw(test_error);
        true -> ok
    end
).

-define(PEFN, list_to_atom(lists:concat(["pef_", ?FUNCTION_NAME]))).

-define(FIXTURE(Configs, TestsList), [
    {setup,
        fun() ->
            persistent_term:put({temporal_sdk_test_replay, config_name}, ConfigName),
            Apps = ?SETUP(Config),
            meck:new(?A_TYPE, [non_strict]),
            EchoFn = fun
                (I) when is_binary(I), byte_size(I) > 10_000 -> ~"redacted_large_payload";
                (I) when is_list(I), length(I) > 3_300 -> ~"redacted_large_payload";
                (I) -> I
            end,
            AEFn = fun
                (#{task := #{attempt := A}}, [_I, T, FA]) when
                    is_integer(T), is_integer(FA), A < FA
                ->
                    timer:sleep(T),
                    throw(test_error);
                (_Context, [I, T, FA]) when is_list(I), is_integer(T), is_integer(FA), T > 0 ->
                    timer:sleep(T),
                    EchoFn(I);
                (_Context, [I, T, FA]) when is_integer(T), is_integer(FA), T > 0 ->
                    timer:sleep(T),
                    [EchoFn(I)];
                (_Context, [I, T]) when is_list(I), is_integer(T), T > 0 ->
                    timer:sleep(T),
                    EchoFn(I);
                (_Context, [I, T]) when is_integer(T), T > 0 ->
                    timer:sleep(T),
                    [EchoFn(I)];
                (_Context, I) when is_list(I) ->
                    EchoFn(I);
                (_Context, I) ->
                    [EchoFn(I)]
            end,
            ACFn = fun
                (#{cancel_requested := true}) -> {cancel, ["details"]};
                (_Context) -> ignore
            end,
            meck:expect(?A_TYPE, execute, AEFn),
            meck:expect(?A_TYPE, handle_heartbeat, fun(_Context) -> heartbeat end),
            meck:expect(?A_TYPE, handle_cancel, ACFn),
            meck:expect(?A_TYPE, handle_message, fun(_Context, Msg) -> {data, Msg} end),
            lists:foreach(
                fun({Fun, Arity}) ->
                    WId = temporal_sdk_utils_path:atom_path([?MODULE, Fun, Arity, workflow]),
                    meck:new(WId, [non_strict]),
                    meck:expect(WId, handle_message, fun(_Name, Value) -> {record, Value} end)
                end,
                ?MECKED_FUNCTIONS_LIST
            ),
            Apps
        end,
        fun(Apps) ->
            lists:foreach(
                fun({Fun, Arity}) ->
                    WId = temporal_sdk_utils_path:atom_path([?MODULE, Fun, Arity, workflow]),
                    meck:unload(WId)
                end,
                ?MECKED_FUNCTIONS_LIST
            ),
            meck:unload(?A_TYPE),
            ?CLEANUP(Apps)
        end,
        TestsList}
 || {ConfigName, Config} <- Configs
]).

-define(CONFIG_NAME, persistent_term:get({temporal_sdk_test_replay, config_name})).

-define(WORKER_CONFIG, [#{namespace => ?NS, task_queue => ?TQ}]).
-define(WORKFLOW_WORKER_CONFIG, [
    #{
        worker_id => ?WF_TYPE,
        namespace => ?NS,
        task_queue => ?TQ,
        task_settings => [session_worker]
    }
]).

-define(CONFIGS, [
    {binaries, [
        {clusters, [
            {?CL, [
                {client, #{
                    grpc_opts => #{codec => {temporal_sdk_codec_binaries, [], []}},
                    grpc_opts_longpoll => #{codec => {temporal_sdk_codec_binaries, [], []}}
                }},
                {activities, ?WORKER_CONFIG},
                {nexuses, ?WORKER_CONFIG},
                {workflows, ?WORKFLOW_WORKER_CONFIG}
            ]}
        ]}
    ]},
    {strings, [
        {clusters, [
            {?CL, [
                {client, #{
                    grpc_opts => #{codec => {temporal_sdk_codec_strings, [], []}},
                    grpc_opts_longpoll => #{codec => {temporal_sdk_codec_strings, [], []}}
                }},
                {activities, ?WORKER_CONFIG},
                {nexuses, ?WORKER_CONFIG},
                {workflows, ?WORKFLOW_WORKER_CONFIG}
            ]}
        ]}
    ]}
]).

-define(MECKED_FUNCTIONS_LIST,
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

execute(_Context, _Input) -> [].
