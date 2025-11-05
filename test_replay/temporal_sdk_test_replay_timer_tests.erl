-module(temporal_sdk_test_replay_timer_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
-include("test_replay/include/temporal_sdk_test_replay_fixtures.hrl").

-define(TESTS, [
    fun noevent/0,
    fun not_awaited/0,
    fun base/0,
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
    fun t_cancel_1/0,
    fun t_cancel_2/0,
    fun t_cancel_2_nde/0,
    fun t_cancel_3/0,
    fun t_cancel_loop/0,
    fun long_fail_await/0,
    fun t_t/0,
    fun t_t_err/0,
    fun t_err_t/0,
    fun err_t_t/0
]).

-define(LPATH, [json, timer]).

base_test_() -> ?FIXTURE(?CONFIGS, {inparallel, {timeout, 10, ?TESTS}}).

noevent() ->
    EFn = fun(_Context, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T),
        {noevent, noevent} = await({marker, none, invalid})
    end,
    ?assertReplayEqual({completed, []}, EFn).

not_awaited() ->
    EFn = fun(_Context, _Input) ->
        start_timer(1)
    end,
    ?assertReplayEqual({completed, []}, EFn).

base() ->
    EFn = fun(_Context, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T)
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

base_nde_1() ->
    EFn = fun(_Context, _Input) ->
        ok
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [base]).

base_nde_2() ->
    EFn = fun(_Context, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T),
        start_activity(?A_TYPE, [])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [base]).

noawait_fail() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        start_timer(1),
        ?THROW_ON_REPLAY
    end,
    ?assertReplayEqual({completed, []}, EFn).

complete() ->
    EFn = fun(_Context, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T),
        complete_workflow_execution([])
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

complete_nde() ->
    EFn = fun(_Context, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T),
        start_activity(?A_TYPE, []),
        complete_workflow_execution([])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [complete]).

complete_prohibited_nde() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T),
        complete_workflow_execution(?DATA),
        case IsReplaying of
            false -> start_activity(?A_TYPE, []);
            true -> set_workflow_result(?DATA)
        end
    end,
    ?assertReplayEqual({completed, ?DATA}, EFn, ?LPATH ++ [complete]).

cancel() ->
    EFn = fun(_Context, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T),
        cancel_workflow_execution([])
    end,
    ?assertReplayEqualF({canceled, []}, EFn, ?LPATH).

cancel_nde() ->
    EFn = fun(_Context, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T),
        start_activity(?A_TYPE, []),
        cancel_workflow_execution([])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [cancel]).

cancel_prohibited_nde() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T),
        cancel_workflow_execution(?DATA),
        case IsReplaying of
            false -> start_activity(?A_TYPE, []);
            true -> set_workflow_result(?DATA)
        end
    end,
    ?assertReplayEqual({canceled, ?DATA}, EFn, ?LPATH ++ [cancel]).

fail() ->
    EFn = fun(_Context, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T),
        fail_workflow_execution(#{source => "Src", message => "Msg", stack_trace => "ST"})
    end,
    ?assertReplayMatchF(
        {failed, #{source := "Src", message := "Msg", stack_trace := "ST"}},
        EFn,
        ?LPATH
    ).

fail_nde() ->
    EFn = fun(_Context, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T),
        start_activity(?A_TYPE, []),
        fail_workflow_execution(#{source => "Src", message => "Msg", stack_trace => "ST"})
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [fail]).

fail_prohibited_nde() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T),
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
        T = start_timer(1, [{timer_id, test_timer_id}]),
        #{state := fired} = wait(T),
        T = start_timer(1, [{timer_id, test_timer_id}]),
        #{state := fired} = wait(T)
    end,
    ?assertReplayEqual({completed, []}, EFn).

throw_1() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T),
        ?THROW_ON_REPLAY
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

throw_2() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        ?THROW_ON_REPLAY,
        T = start_timer(1),
        #{state := fired} = wait(T)
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

throw_12() ->
    EFn = fun(_Context, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T)
    end,
    ?assertReplayEqual({completed, []}, EFn, ?LPATH ++ [throw_2]).

throw_21() ->
    EFn = fun(_Context, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T)
    end,
    ?assertReplayEqual({completed, []}, EFn, ?LPATH ++ [throw_1]).

throw_nde_1() ->
    EFn = fun(_Context, _Input) ->
        T = start_timer(1),
        #{state := fired} = wait(T),
        start_activity(?A_TYPE, [])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [throw_1]).

throw_nde_2() ->
    EFn = fun(_Context, _Input) ->
        start_activity(?A_TYPE, []),
        T = start_timer(1),
        #{state := fired} = wait(T)
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [throw_2]).

loop() ->
    EFn = fun(_Context, _Input) ->
        Seq = lists:seq(1, ?LOOP_SIZE),
        TL = [start_timer(1) || _I <- Seq],
        [] = lists:filter(fun(#{state := fired}) -> false end, wait_all(TL))
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

loop_nde_1() ->
    EFn = fun(_Context, _Input) ->
        start_activity(?A_TYPE, []),
        Seq = lists:seq(1, ?LOOP_SIZE),
        TL = [start_timer(1) || _I <- Seq],
        [] = lists:filter(fun(#{state := fired}) -> false end, wait_all(TL))
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [loop]).

loop_nde_2() ->
    EFn = fun(_Context, _Input) ->
        Seq = lists:seq(1, ?LOOP_SIZE),
        TL = [start_timer(1) || _I <- Seq],
        [] = lists:filter(fun(#{state := fired}) -> false end, wait_all(TL)),
        start_activity(?A_TYPE, [])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [loop]).

t_cancel_1() ->
    EFn = fun(_Context, _Input) ->
        T = start_timer(10_000),
        cancel_timer(T),
        #{state := canceled, cancel_requested := true} = wait(T)
    end,
    ?assertReplayEqual({completed, []}, EFn).

t_cancel_2() ->
    EFn = fun(_Context, _Input) ->
        T1 = start_timer(10_000),
        T2 = start_timer(1),
        #{state := cmd} = wait(setelement(1, T1, timer_cmd)),
        #{state := cmd} = wait(setelement(1, T1, timer_cmd), 100),
        #{state := fired} = wait(T2),
        cancel_timer(T1),
        #{state := canceled} = wait(T1)
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

t_cancel_2_nde() ->
    EFn = fun(_Context, _Input) ->
        T1 = start_timer(10_000),
        T2 = start_timer(1),
        #{state := fired} = wait(T2),
        start_activity(?A_TYPE, []),
        cancel_timer(T1),
        #{state := canceled} = wait(T1)
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [t_cancel_2]).

t_cancel_3() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        T1 = start_timer(10_000),
        T2 = start_timer(1),
        #{state := fired} = wait(T2),
        ?THROW_ON_REPLAY,
        cancel_timer(T1),
        #{state := canceled} = wait(T1)
    end,
    ?assertReplayEqual({completed, []}, EFn).

t_cancel_loop() ->
    EFn = fun(_Context, _Input) ->
        Seq = lists:seq(1, ?LOOP_SIZE),
        TL1 = [start_timer(1) || _I <- Seq],
        TL2 = [start_timer(10_000) || _I <- Seq],
        [] = lists:filter(fun(#{state := fired}) -> false end, wait_all(TL1)),
        [cancel_timer(T) || T <- TL2],
        [] = lists:filter(fun(#{state := canceled}) -> false end, wait_all(TL2))
    end,
    ?assertReplayEqual({completed, []}, EFn).

long_fail_await() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        T = start_timer(100),
        ?THROW_ON_REPLAY,
        #{state := fired} = wait(T)
    end,
    ?assertReplayEqual({completed, []}, EFn).

t_t() ->
    EFn = fun(_Context, _Input) ->
        T1 = start_timer(1),
        #{state := fired} = wait(T1),
        T2 = start_timer(1),
        #{state := fired} = wait(T2)
    end,
    ?assertReplayEqual({completed, []}, EFn).

t_t_err() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        T1 = start_timer(1),
        #{state := fired} = wait(T1),
        T2 = start_timer(1),
        #{state := fired} = wait(T2),
        ?THROW_ON_REPLAY
    end,
    ?assertReplayEqual({completed, []}, EFn).

t_err_t() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        T1 = start_timer(1),
        #{state := fired} = wait(T1),
        ?THROW_ON_REPLAY,
        T2 = start_timer(1),
        #{state := fired} = wait(T2)
    end,
    ?assertReplayEqual({completed, []}, EFn).

err_t_t() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        ?THROW_ON_REPLAY,
        T1 = start_timer(1),
        #{state := fired} = wait(T1),
        T2 = start_timer(1),
        #{state := fired} = wait(T2)
    end,
    ?assertReplayEqual({completed, []}, EFn).

-endif.
