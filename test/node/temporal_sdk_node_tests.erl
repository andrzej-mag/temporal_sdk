-module(temporal_sdk_node_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
-include("test/include/temporal_sdk_test_fixtures_unit.hrl").

-import(temporal_sdk_node, [
    stats/0,
    os_stats/0,
    os_disk_mounts/0,
    setup/2
]).

-define(BASE_TESTS, [
    fun t_stats/1,
    fun t_os_stats/1,
    fun t_os_disk_mounts/1
]).

base_test_() -> ?FIXTURE(?CONFIGS_BASE, ?BASE_TESTS).

t_stats({_Clusters, _Config}) ->
    ?assertMatch(#{}, stats()).

t_os_stats({_Clusters, _Config}) ->
    ?assertMatch(#{}, os_stats()).

t_os_disk_mounts({_Clusters, _Config}) ->
    ?assertMatch([_ | _], os_disk_mounts()).

setup_test() ->
    ?assertMatch(
        {ok, _, _, _},
        setup(node, #{})
    ),
    ?assertMatch(
        {ok, _, _, _},
        setup(node, [])
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
