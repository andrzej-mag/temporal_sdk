-module(temporal_sdk_test_replay_benchmark_tests).

-ifdef(TEST).

-export([
    activity_parallel_execution/2,
    marker_parallel_execution/2
]).

-include_lib("eunit/include/eunit.hrl").
-include("test_replay/include/temporal_sdk_test_replay_fixtures.hrl").

-define(TESTS, [
    {timeout, 10, fun activity/0},
    {timeout, 10, fun activity_parallel/0},
    {timeout, 10, fun marker/0},
    {timeout, 10, fun marker_parallel/0}
]).

base_test_() -> ?FIXTURE(?CONFIGS, {inparallel, {timeout, 20, ?TESTS}}).

-define(BENCH_SIZE, 1000).
-define(EXECUTIONS_SIZE, 10).

activity() ->
    EFn = fun(_Context, _Input) ->
        StartTime = erlang:system_time(millisecond),
        Seq = lists:seq(1, ?BENCH_SIZE),
        AL = [start_activity(?A_TYPE, [I], [{activity_id, integer_to_list(I)}]) || I <- Seq],
        Seq = lists:map(fun(#{result := [R]}) -> R end, wait_all(AL)),
        APS = round(?BENCH_SIZE / (erlang:system_time(millisecond) - StartTime) * 1_000),
        ?debugFmt("~n~p-~p: ~p activities/sec~n", [?CONFIG_NAME, ?FUNCTION_NAME, APS])
    end,
    ?assertReplayEqualF({completed, []}, EFn, [json, benchmark]).

activity_parallel() ->
    EFn = fun(_Context, _Input) ->
        StartTime = erlang:system_time(millisecond),
        SeqE = lists:seq(1, ?EXECUTIONS_SIZE),
        SeqA = lists:seq(1, round(?BENCH_SIZE / ?EXECUTIONS_SIZE)),
        EL = [
            start_execution(?MODULE, activity_parallel_execution, [SeqA], [{execution_id, Count}])
         || Count <- SeqE
        ],
        SeqE = lists:map(fun(#{result := R}) -> R end, wait_all(EL)),
        APS = round(?BENCH_SIZE / (erlang:system_time(millisecond) - StartTime) * 1_000),
        ?debugFmt("~n~p-~p: ~p activities/sec~n", [?CONFIG_NAME, ?FUNCTION_NAME, APS])
    end,
    ?assertReplayEqualF({completed, []}, EFn, [json, benchmark]).

activity_parallel_execution(#{execution_id := Id}, [Seq]) ->
    AL = [
        start_activity(?A_TYPE, [I], [{activity_id, lists:concat([Id, "/", integer_to_list(I)])}])
     || I <- Seq
    ],
    Seq = lists:map(fun(#{result := [R]}) -> R end, wait_all(AL)),
    Id.

marker() ->
    EFn = fun(_Context, _Input) ->
        StartTime = erlang:system_time(millisecond),
        Seq = lists:seq(1, ?BENCH_SIZE),
        ML = [
            record_marker(fun() -> [I] end, [{marker_name, integer_to_list(I)}])
         || I <- Seq
        ],
        Seq = lists:map(fun(#{value := [R]}) -> R end, wait_all(ML)),
        APS = round(?BENCH_SIZE / (erlang:system_time(millisecond) - StartTime) * 1_000),
        ?debugFmt("~n~p-~p: ~p markers/sec~n", [?CONFIG_NAME, ?FUNCTION_NAME, APS])
    end,
    ?assertReplayEqualF({completed, []}, EFn, [json, benchmark, ?CONFIG_NAME]).

marker_parallel() ->
    EFn = fun(_Context, _Input) ->
        StartTime = erlang:system_time(millisecond),
        SeqE = lists:seq(1, ?EXECUTIONS_SIZE),
        SeqA = lists:seq(1, round(?BENCH_SIZE / ?EXECUTIONS_SIZE)),
        EL = [
            start_execution(?MODULE, marker_parallel_execution, [SeqA], [{execution_id, Count}])
         || Count <- SeqE
        ],
        SeqE = lists:map(fun(#{result := R}) -> R end, wait_all(EL)),
        APS = round(?BENCH_SIZE / (erlang:system_time(millisecond) - StartTime) * 1_000),
        ?debugFmt("~n~p-~p: ~p markers/sec~n", [?CONFIG_NAME, ?FUNCTION_NAME, APS])
    end,
    ?assertReplayEqualF({completed, []}, EFn, [json, benchmark, ?CONFIG_NAME]).

marker_parallel_execution(#{execution_id := Id}, [Seq]) ->
    ML = [
        record_marker(fun() -> [I] end, [{marker_name, lists:concat([Id, "/", integer_to_list(I)])}])
     || I <- Seq
    ],
    Seq = lists:map(fun(#{value := [R]}) -> R end, wait_all(ML)),
    Id.

-endif.
