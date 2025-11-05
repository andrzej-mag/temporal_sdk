-module(temporal_sdk_test_replay_info_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
-include("test_replay/include/temporal_sdk_test_replay_fixtures.hrl").

-define(TESTS, [
    fun base/0,
    fun noevent/0,
    fun base_nde_1/0,
    fun base_nde_2/0,
    fun noawait_fail/0,
    fun complete/0,
    fun complete_nde/0,
    fun complete_prohibited_nde/0,
    fun cancel/0,
    fun cancel_nde/0,
    fun cancel_prohibited_nde/0,
    fun fail/0,
    fun fail_nde/0,
    fun fail_prohibited_nde/0,
    fun duplicate_id/0,
    fun throw_1/0,
    fun throw_2/0,
    fun throw_12/0,
    fun throw_21/0,
    fun throw_nde_1/0,
    fun throw_nde_2/0,
    fun loop/0,
    fun loop_nde_1/0,
    fun loop_nde_2/0,
    fun i_i/0,
    fun i_i_err/0,
    fun i_err_i/0,
    fun err_i_i/0,
    % fun m_failing/0,
    fun large_data/0
]).

-define(LPATH, [json, info]).

base_test_() -> ?FIXTURE(?CONFIGS, {inparallel, {timeout, 10, ?TESTS}}).

base() ->
    EFn = fun(_Context, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I))
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

noevent() ->
    EFn = fun(_Context, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I)),
        {noevent, noevent} = await({marker, none, invalid})
    end,
    ?assertReplayEqual({completed, []}, EFn, ?LPATH ++ [base]).

base_nde_1() ->
    EFn = fun(_Context, _Input) ->
        ok
    end,
    ?assertReplayEqual({completed, []}, EFn, ?LPATH ++ [base]).

base_nde_2() ->
    EFn = fun(_Context, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I)),
        start_activity(?A_TYPE, [])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [base]).

noawait_fail() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        set_info(?DATA),
        ?THROW_ON_REPLAY
    end,
    ?assertReplayEqual({completed, []}, EFn).

complete() ->
    EFn = fun(_Context, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I)),
        complete_workflow_execution([])
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

complete_nde() ->
    EFn = fun(_Context, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I)),
        start_activity(?A_TYPE, []),
        complete_workflow_execution([])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [complete]).

complete_prohibited_nde() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I)),
        complete_workflow_execution(?DATA),
        case IsReplaying of
            false -> start_activity(?A_TYPE, []);
            true -> set_workflow_result(?DATA)
        end
    end,
    ?assertReplayEqual({completed, ?DATA}, EFn, ?LPATH ++ [complete]).

cancel() ->
    EFn = fun(_Context, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I)),
        cancel_workflow_execution([])
    end,
    ?assertReplayEqualF({canceled, []}, EFn, ?LPATH).

cancel_nde() ->
    EFn = fun(_Context, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I)),
        start_activity(?A_TYPE, []),
        cancel_workflow_execution([])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [cancel]).

cancel_prohibited_nde() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I)),
        cancel_workflow_execution(?DATA),
        case IsReplaying of
            false -> start_activity(?A_TYPE, []);
            true -> set_workflow_result(?DATA)
        end
    end,
    ?assertReplayEqual({canceled, ?DATA}, EFn, ?LPATH ++ [cancel]).

fail() ->
    EFn = fun(_Context, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I)),
        fail_workflow_execution(#{source => "Src", message => "Msg", stack_trace => "ST"})
    end,
    ?assertReplayMatchF(
        {failed, #{source := "Src", message := "Msg", stack_trace := "ST"}},
        EFn,
        ?LPATH
    ).

fail_nde() ->
    EFn = fun(_Context, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I)),
        start_activity(?A_TYPE, []),
        fail_workflow_execution(#{source => "Src", message => "Msg", stack_trace => "ST"})
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [fail]).

fail_prohibited_nde() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I)),
        fail_workflow_execution(#{source => "Src", message => "Msg", stack_trace => "ST"}),
        case IsReplaying of
            false -> start_activity(?A_TYPE, []);
            true -> set_workflow_result(?DATA)
        end
    end,
    ?assertReplayMatch(
        {failed, #{source := "Src", message := "Msg", stack_trace := "ST"}},
        EFn,
        ?LPATH ++ [fail]
    ).

duplicate_id() ->
    EFn = fun(_Context, _Input) ->
        I1 = set_info([1], [{info_id, test_info}]),
        ?assertMatch([_], wait(I1)),
        I2 = set_info([2], [{info_id, test_info}]),
        ?assertMatch([_], wait(I2)),
        I3 = set_info([3], [{info_id, test_info}]),
        ?assertMatch([_], wait(I3))
    end,
    ?assertReplayEqual({completed, []}, EFn).

throw_1() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I)),
        ?THROW_ON_REPLAY
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

throw_2() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        ?THROW_ON_REPLAY,
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I))
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

throw_12() ->
    EFn = fun(_Context, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I))
    end,
    ?assertReplayEqual({completed, []}, EFn, ?LPATH ++ [throw_2]).

throw_21() ->
    EFn = fun(_Context, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I))
    end,
    ?assertReplayEqual({completed, []}, EFn, ?LPATH ++ [throw_1]).

throw_nde_1() ->
    EFn = fun(_Context, _Input) ->
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I)),
        start_activity(?A_TYPE, [])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [throw_1]).

throw_nde_2() ->
    EFn = fun(_Context, _Input) ->
        start_activity(?A_TYPE, []),
        I = set_info(?DATA),
        ?assertEqual(?DATA, wait(I))
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [throw_2]).

loop() ->
    EFn = fun(_Context, _Input) ->
        Seq = lists:seq(1, ?LOOP_SIZE),
        IL = [set_info(I, [{info_id, I}]) || I <- Seq],
        ?assertEqual(Seq, wait_all(IL))
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

loop_nde_1() ->
    EFn = fun(_Context, _Input) ->
        start_activity(?A_TYPE, []),
        Seq = lists:seq(1, ?LOOP_SIZE),
        IL = [set_info(I, [{info_id, I}]) || I <- Seq],
        ?assertEqual(Seq, wait_all(IL))
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [loop]).

loop_nde_2() ->
    EFn = fun(_Context, _Input) ->
        Seq = lists:seq(1, ?LOOP_SIZE),
        IL = [set_info(I, [{info_id, I}]) || I <- Seq],
        ?assertEqual(Seq, wait_all(IL)),
        start_activity(?A_TYPE, [])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [loop]).

i_i() ->
    EFn = fun(_Context, _Input) ->
        I1 = set_info(?DATA, [{info_id, test_info1}]),
        ?assertEqual(?DATA, wait(I1)),
        I2 = set_info(?DATA, [{info_id, test_info2}]),
        ?assertEqual(?DATA, wait(I2))
    end,
    ?assertReplayEqual({completed, []}, EFn).

i_i_err() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        I1 = set_info(?DATA, [{info_id, test_info1}]),
        ?assertEqual(?DATA, wait(I1)),
        I2 = set_info(?DATA, [{info_id, test_info2}]),
        ?assertEqual(?DATA, wait(I2)),
        ?THROW_ON_REPLAY
    end,
    ?assertReplayEqual({completed, []}, EFn).

i_err_i() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        I1 = set_info(?DATA, [{info_id, test_info1}]),
        ?assertEqual(?DATA, wait(I1)),
        ?THROW_ON_REPLAY,
        I2 = set_info(?DATA, [{info_id, test_info2}]),
        ?assertEqual(?DATA, wait(I2))
    end,
    ?assertReplayEqual({completed, []}, EFn).

err_i_i() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        ?THROW_ON_REPLAY,
        I1 = set_info(?DATA, [{info_id, test_info1}]),
        ?assertEqual(?DATA, wait(I1)),
        I2 = set_info(?DATA, [{info_id, test_info2}]),
        ?assertEqual(?DATA, wait(I2))
    end,
    ?assertReplayEqual({completed, []}, EFn).

large_data() ->
    EFn = fun(_Context, _Input) ->
        LargeData = lists:flatten(lists:duplicate(100_000, "X")),
        I = set_info(LargeData),
        ?assertEqual(LargeData, wait(I))
    end,
    ?assertReplayEqual({completed, []}, EFn).

-endif.
