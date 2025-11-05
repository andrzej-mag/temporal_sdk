-module(temporal_sdk_test_replay_query_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
-include("test_replay/include/temporal_sdk_test_replay_fixtures.hrl").

-define(TESTS, [
    fun base/0
]).

base_test_() -> ?FIXTURE(?CONFIGS, {inparallel, {timeout, 10, ?TESTS}}).

-define(QUERY_TYPE, "test_query").

base() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, ["ok", 500]),
        case await({query_request, ?QUERY_TYPE}) of
            {ok, _} -> respond_query({query, ?QUERY_TYPE}, [{answer, ["open result"]}]);
            _ -> ok
        end,
        await(A)
    end,
    HQFn = fun(_History, _Query) ->
        #{answer => ["closed result"]}
    end,

    WMod = temporal_sdk_utils_path:atom_path([?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, workflow]),
    meck:expect(WMod, execute, EFn),
    meck:expect(WMod, handle_query, HQFn),

    WId = temporal_sdk_utils_path:string_path([?BASE_DIR, ?MODULE, ?FUNCTION_NAME, ?CONFIG_NAME]),
    {ok, #{workflow_execution := WE}} =
        temporal_sdk:start_workflow(?CL, ?TQ, WMod, [{namespace, ?NS}, {workflow_id, WId}]),
    ?assertMatch(
        {ok, #{query_result := [_]}},
        temporal_sdk_service:query_workflow(?CL, WE, ?QUERY_TYPE, [
            {namespace, ?NS}, {query_args, ["query args"]}
        ])
    ),
    ?assertMatch(
        {ok, {completed, #{result := []}}}, temporal_sdk:await_workflow(?CL, WE, [{namespace, ?NS}])
    ),
    ?assertMatch(
        {ok, #{query_result := ["closed result"]}},
        temporal_sdk_service:query_workflow(?CL, WE, ?QUERY_TYPE, [
            {namespace, ?NS}, {query_args, ["query args"]}
        ])
    ).

-endif.
