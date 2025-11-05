-module(temporal_sdk_test_replay_marker_tests).

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
    fun m_m/0,
    fun m_m_err/0,
    fun m_err_m/0,
    fun err_m_m/0,
    fun m_failing/0,
    fun large_data/0
]).

-define(OPTS, []).
-define(LPATH, [json, marker, ?CONFIG_NAME]).
-define(MFn, fun() -> ?DATA end).

base_test_() -> ?FIXTURE(?CONFIGS, {inparallel, {timeout, 10, ?TESTS}}).

base() ->
    EFn = fun(_Context, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
        #{value := ?DATA} = wait(setelement(1, M, marker))
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

noevent() ->
    EFn = fun(_Context, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
        {noevent, noevent} = await({marker, none, invalid})
    end,
    ?assertReplayEqual({completed, []}, EFn, ?LPATH ++ [base]).

base_nde_1() ->
    EFn = fun(_Context, _Input) ->
        ok
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [base]).

base_nde_2() ->
    EFn = fun(_Context, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
        start_activity(?A_TYPE, [])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [base]).

noawait_fail() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        record_marker(?MFn, ?OPTS),
        ?THROW_ON_REPLAY
    end,
    ?assertReplayEqual({completed, []}, EFn).

complete() ->
    EFn = fun(_Context, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
        complete_workflow_execution([])
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

complete_nde() ->
    EFn = fun(_Context, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
        start_activity(?A_TYPE, []),
        complete_workflow_execution([])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [complete]).

complete_prohibited_nde() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
        complete_workflow_execution(?DATA),
        case IsReplaying of
            false -> start_activity(?A_TYPE, []);
            true -> set_workflow_result(?DATA)
        end
    end,
    ?assertReplayEqual({completed, ?DATA}, EFn, ?LPATH ++ [complete]).

cancel() ->
    EFn = fun(_Context, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
        cancel_workflow_execution([])
    end,
    ?assertReplayEqualF({canceled, []}, EFn, ?LPATH).

cancel_nde() ->
    EFn = fun(_Context, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
        start_activity(?A_TYPE, []),
        cancel_workflow_execution([])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [cancel]).

cancel_prohibited_nde() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
        cancel_workflow_execution(?DATA),
        case IsReplaying of
            false -> start_activity(?A_TYPE, []);
            true -> set_workflow_result(?DATA)
        end
    end,
    ?assertReplayEqual({canceled, ?DATA}, EFn, ?LPATH ++ [cancel]).

fail() ->
    EFn = fun(_Context, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
        fail_workflow_execution(#{source => "Src", message => "Msg", stack_trace => "ST"})
    end,
    ?assertReplayMatchF(
        {failed, #{source := "Src", message := "Msg", stack_trace := "ST"}},
        EFn,
        ?LPATH
    ).

fail_nde() ->
    EFn = fun(_Context, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
        start_activity(?A_TYPE, []),
        fail_workflow_execution(#{source => "Src", message => "Msg", stack_trace => "ST"})
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [fail]).

fail_prohibited_nde() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
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
        M1 = record_marker(fun() -> [1] end, [{marker_name, marker_1} | ?OPTS]),
        ?assertMatch(#{value := [_]}, wait(M1)),
        M1 = record_marker(fun() -> [2] end, [{marker_name, marker_1} | ?OPTS]),
        ?assertMatch(#{value := [_]}, wait(M1)),
        M1 = record_marker(fun() -> [3] end, [{marker_name, marker_1} | ?OPTS]),
        ?assertMatch(#{value := [_]}, wait(M1))
    end,
    ?assertReplayEqual({completed, []}, EFn).

throw_1() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
        ?THROW_ON_REPLAY
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

throw_2() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        ?THROW_ON_REPLAY,
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M)
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

throw_12() ->
    EFn = fun(_Context, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M)
    end,
    ?assertReplayEqual({completed, []}, EFn, ?LPATH ++ [throw_2]).

throw_21() ->
    EFn = fun(_Context, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M)
    end,
    ?assertReplayEqual({completed, []}, EFn, ?LPATH ++ [throw_1]).

throw_nde_1() ->
    EFn = fun(_Context, _Input) ->
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M),
        start_activity(?A_TYPE, [])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [throw_1]).

throw_nde_2() ->
    EFn = fun(_Context, _Input) ->
        start_activity(?A_TYPE, []),
        M = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M)
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [throw_2]).

loop() ->
    EFn = fun(_Context, _Input) ->
        Seq = lists:seq(1, ?LOOP_SIZE),
        ML = [record_marker(fun() -> [I] end, ?OPTS) || I <- Seq],
        ?assertEqual(Seq, lists:map(fun(#{value := [R]}) -> R end, wait_all(ML)))
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

loop_nde_1() ->
    EFn = fun(_Context, _Input) ->
        start_activity(?A_TYPE, []),
        Seq = lists:seq(1, ?LOOP_SIZE),
        ML = [record_marker(fun() -> [I] end, ?OPTS) || I <- Seq],
        ?assertEqual(Seq, lists:map(fun(#{value := [R]}) -> R end, wait_all(ML)))
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [loop]).

loop_nde_2() ->
    EFn = fun(_Context, _Input) ->
        Seq = lists:seq(1, ?LOOP_SIZE),
        ML = [record_marker(fun() -> [I] end, ?OPTS) || I <- Seq],
        ?assertEqual(Seq, lists:map(fun(#{value := [R]}) -> R end, wait_all(ML))),
        start_activity(?A_TYPE, [])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [loop]).

m_m() ->
    EFn = fun(_Context, _Input) ->
        M1 = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M1),
        M2 = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M2)
    end,
    ?assertReplayEqual({completed, []}, EFn).

m_m_err() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        M1 = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M1),
        M2 = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M2),
        ?THROW_ON_REPLAY
    end,
    ?assertReplayEqual({completed, []}, EFn).

m_err_m() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        M1 = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M1),
        ?THROW_ON_REPLAY,
        M2 = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M2)
    end,
    ?assertReplayEqual({completed, []}, EFn).

err_m_m() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        ?THROW_ON_REPLAY,
        M1 = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M1),
        M2 = record_marker(?MFn, ?OPTS),
        #{value := ?DATA} = wait(M2)
    end,
    ?assertReplayEqual({completed, []}, EFn).

m_failing() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        Fn = fun() ->
            case IsReplaying of
                false -> throw(test_error);
                true -> ?DATA
            end
        end,
        M = record_marker(Fn, ?OPTS),
        #{value := ?DATA} = wait(M)
    end,
    ?assertReplayEqual({completed, []}, EFn).

large_data() ->
    EFn = fun(_Context, _Input) ->
        LargeData = [binary:copy(~"X", 2_000_000)],
        M = record_marker(fun() -> LargeData end, ?OPTS),
        #{value := LargeData} = wait(M)
    end,
    ?assertReplayEqual({completed, []}, EFn).

-endif.
