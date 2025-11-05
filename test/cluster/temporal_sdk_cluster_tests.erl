-module(temporal_sdk_cluster_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
-include("test/include/temporal_sdk_test_fixtures_unit.hrl").

-import(temporal_sdk_cluster, [
    is_alive/1,
    list/0,
    stats/1,
    setup/2
]).

-define(BASE_TESTS, [
    fun t_is_alive/1,
    fun t_list/1,
    fun t_stats/1
]).

base_test_() -> ?FIXTURE(?CONFIGS_BASE, ?BASE_TESTS).

t_is_alive({Clusters, _Config}) ->
    lists:foreach(
        fun(Cluster) ->
            ?assertEqual(true, is_alive(Cluster))
        end,
        Clusters
    ),

    ?assertMatch({error, _}, is_alive(invalid_cluster)).

t_list({Clusters, _Config}) ->
    ?assertEqual(lists:sort(Clusters), lists:sort(list())).

t_stats({Clusters, _Config}) ->
    lists:foreach(
        fun(Cluster) ->
            ?assertMatch({ok, #{}}, stats(Cluster))
        end,
        Clusters
    ),

    ?assertMatch({error, _}, stats(invalid_cluster)).

setup_test() ->
    ?assertMatch(
        {ok, _, _, _},
        setup(test_name, #{})
    ),
    ?assertMatch(
        {ok, _, _, _},
        setup(test_name, [])
    ),
    ?assertMatch(
        {ok, _, _, _},
        setup(test_name, #{limiter_time_windows => #{activity_regular => 1_000}})
    ),

    ?assertMatch(
        {error, _},
        setup(test_name, #{invalid_k => invalid_v})
    ),
    ?assertMatch(
        {error, _},
        setup(test_name, #{limiter_time_windows => #{invalid_task => 1_000}})
    ).

-endif.
