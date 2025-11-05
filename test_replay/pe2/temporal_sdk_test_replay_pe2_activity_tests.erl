-module(temporal_sdk_test_replay_pe2_activity_tests).

-ifdef(TEST).

-export([
    execution_1/2
]).
-export([
    pef_noevent/2,
    pef_not_awaited/2,
    pef_base/2,
    pef_base_nde_1/2,
    pef_base_nde_2/2,
    pef_noawait_fail/2,
    pef_complete/2,
    pef_complete_nde/2,
    pef_complete_prohibited_nde/2,
    pef_cancel/2,
    pef_cancel_nde/2,
    pef_cancel_prohibited_nde/2,
    pef_fail/2,
    pef_fail_nde/2,
    pef_fail_prohibited_nde/2,
    pef_duplicate_id/2,
    pef_throw_1/2,
    pef_throw_2/2,
    pef_throw_12/2,
    pef_throw_21/2,
    pef_throw_nde_1/2,
    pef_throw_nde_2/2,
    pef_loop/2,
    pef_loop_nde_1/2,
    pef_loop_nde_2/2,
    pef_a_cancel_1/2,
    pef_a_cancel_2/2,
    pef_a_cancel_3/2,
    pef_a_cancel_3_nde1/2,
    pef_a_cancel_3_nde2/2,
    pef_a_cancel_4/2,
    pef_a_cancel_5/2,
    pef_a_cancel_6/2,
    pef_a_cancel_loop/2,
    % pef_invalid_mod/2,
    pef_long_fail_await/2,
    pef_a_a/2,
    pef_a_a_err/2,
    pef_a_err_a/2,
    pef_err_a_a/2,
    pef_a_failing_1/2,
    pef_a_failing_2/2,
    pef_a_failing_3/2,
    pef_large_data/2
]).

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
    fun a_cancel_1/0,
    fun a_cancel_2/0,
    fun a_cancel_3/0,
    fun a_cancel_3_nde1/0,
    fun a_cancel_3_nde2/0,
    fun a_cancel_4/0,
    fun a_cancel_5/0,
    fun a_cancel_6/0,
    fun a_cancel_loop/0,
    % fun invalid_mod/0,
    {timeout, 7, fun long_fail_await/0},
    {timeout, 7, fun a_a/0},
    {timeout, 7, fun a_a_err/0},
    {timeout, 7, fun a_err_a/0},
    {timeout, 7, fun err_a_a/0},
    {timeout, 7, fun a_failing_1/0},
    {timeout, 7, fun a_failing_2/0},
    {timeout, 7, fun a_failing_3/0},
    {timeout, 7, fun large_data/0}
]).

-define(OPTS, []).
-define(LPATH, [json, pe2, activity]).

base_test_() -> ?FIXTURE(?CONFIGS, {inparallel, {timeout, 10, ?TESTS}}).

-define(MAIN_EXEC, fun(#{is_replaying := IsReplaying}, _Input) ->
    start_execution(?MODULE, execution_1, [?PEFN, IsReplaying], [{execution_id, exe_1}]),
    "execution_main_result"
end).

execution_1(_Context, [PEFN, IsReplaying]) ->
    start_execution(?MODULE, PEFN, [IsReplaying], [{execution_id, pef}]),
    "execution_1_result".

noevent() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_noevent(_Context, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]),
    {noevent, noevent} = await({marker, none, invalid}).

not_awaited() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_not_awaited(_Context, _Input) ->
    start_activity(?A_TYPE, ?DATA, ?OPTS).

base() ->
    ?assertReplayEqualF({completed, []}, ?MAIN_EXEC, ?LPATH).
pef_base(_Context, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]).

base_nde_1() ->
    ?assertReplayMatch({error, _}, ?MAIN_EXEC, ?LPATH ++ [base]).
pef_base_nde_1(_Context, _Input) ->
    ok.

base_nde_2() ->
    ?assertReplayMatch({error, _}, ?MAIN_EXEC, ?LPATH ++ [base]).
pef_base_nde_2(_Context, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]),
    start_activity(?A_TYPE, [], ?OPTS).

noawait_fail() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_noawait_fail(_Context, [IsReplaying]) ->
    start_activity(?A_TYPE, ?DATA, ?OPTS),
    ?THROW_ON_REPLAY.

complete() ->
    ?assertReplayEqualF({completed, []}, ?MAIN_EXEC, ?LPATH).
pef_complete(_Context, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]),
    #{result := "execution_main_result"} = wait({execution, main}),
    #{result := "execution_1_result"} = wait({execution, exe_1}),
    complete_workflow_execution([]).

complete_nde() ->
    ?assertReplayMatch({error, _}, ?MAIN_EXEC, ?LPATH ++ [complete]).
pef_complete_nde(_Context, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]),
    start_activity(?A_TYPE, [], ?OPTS),
    #{result := "execution_main_result"} = wait({execution, main}),
    #{result := "execution_1_result"} = wait({execution, exe_1}),
    complete_workflow_execution([]).

complete_prohibited_nde() ->
    ?assertReplayEqual({completed, ?DATA}, ?MAIN_EXEC, ?LPATH ++ [complete]).
pef_complete_prohibited_nde(#{is_replaying := IsReplaying}, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]),
    #{result := "execution_main_result"} = wait({execution, main}),
    #{result := "execution_1_result"} = wait({execution, exe_1}),
    complete_workflow_execution(?DATA),
    case IsReplaying of
        false -> start_activity(?A_TYPE, []);
        true -> set_workflow_result(?DATA)
    end.

cancel() ->
    ?assertReplayEqualF({canceled, []}, ?MAIN_EXEC, ?LPATH).
pef_cancel(_Context, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]),
    #{result := "execution_main_result"} = wait({execution, main}),
    #{result := "execution_1_result"} = wait({execution, exe_1}),
    cancel_workflow_execution([]).

cancel_nde() ->
    ?assertReplayMatch({error, _}, ?MAIN_EXEC, ?LPATH ++ [cancel]).
pef_cancel_nde(_Context, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]),
    start_activity(?A_TYPE, [], ?OPTS),
    #{result := "execution_main_result"} = wait({execution, main}),
    #{result := "execution_1_result"} = wait({execution, exe_1}),
    cancel_workflow_execution([]).

cancel_prohibited_nde() ->
    ?assertReplayEqual({canceled, ?DATA}, ?MAIN_EXEC, ?LPATH ++ [cancel]).
pef_cancel_prohibited_nde(#{is_replaying := IsReplaying}, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]),
    #{result := "execution_main_result"} = wait({execution, main}),
    #{result := "execution_1_result"} = wait({execution, exe_1}),
    cancel_workflow_execution(?DATA),
    case IsReplaying of
        false -> start_activity(?A_TYPE, []);
        true -> set_workflow_result(?DATA)
    end.

fail() ->
    ?assertReplayMatchF(
        {failed, #{source := "Src", message := "Msg", stack_trace := "ST"}},
        ?MAIN_EXEC,
        ?LPATH
    ).
pef_fail(_Context, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]),
    #{result := "execution_main_result"} = wait({execution, main}),
    #{result := "execution_1_result"} = wait({execution, exe_1}),
    fail_workflow_execution(#{source => "Src", message => "Msg", stack_trace => "ST"}).

fail_nde() ->
    ?assertReplayMatch({error, _}, ?MAIN_EXEC, ?LPATH ++ [fail]).
pef_fail_nde(_Context, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]),
    start_activity(?A_TYPE, [], ?OPTS),
    #{result := "execution_main_result"} = wait({execution, main}),
    #{result := "execution_1_result"} = wait({execution, exe_1}),
    fail_workflow_execution(#{source => "Src", message => "Msg", stack_trace => "ST"}).

fail_prohibited_nde() ->
    ?assertReplayMatch(
        {failed, #{source := "Src", message := "Msg", stack_trace := "ST"}},
        ?MAIN_EXEC,
        ?LPATH ++ [fail]
    ).
pef_fail_prohibited_nde(#{is_replaying := IsReplaying}, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]),
    #{result := "execution_main_result"} = wait({execution, main}),
    #{result := "execution_1_result"} = wait({execution, exe_1}),
    fail_workflow_execution(#{source => "Src", message => "Msg", stack_trace => "ST"}),
    case IsReplaying of
        false -> start_activity(?A_TYPE, []);
        true -> set_workflow_result(?DATA)
    end.

duplicate_id() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_duplicate_id(_Context, _Input) ->
    A1 = start_activity(?A_TYPE, [], [{activity_id, "test_id"} | ?OPTS]),
    #{state := completed} = wait(A1),
    A2 = start_activity(?A_TYPE, [], [{activity_id, "test_id"} | ?OPTS]),
    #{state := completed} = wait(A2).

throw_1() ->
    ?assertReplayEqualF({completed, []}, ?MAIN_EXEC, ?LPATH).
pef_throw_1(_Context, [IsReplaying]) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]),
    ?THROW_ON_REPLAY.

throw_2() ->
    ?assertReplayEqualF({completed, []}, ?MAIN_EXEC, ?LPATH).
pef_throw_2(_Context, [IsReplaying]) ->
    ?THROW_ON_REPLAY,
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]).

throw_12() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC, ?LPATH ++ [throw_2]).
pef_throw_12(_Context, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]).

throw_21() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC, ?LPATH ++ [throw_1]).
pef_throw_21(_Context, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]).

throw_nde_1() ->
    ?assertReplayMatch({error, _}, ?MAIN_EXEC, ?LPATH ++ [throw_1]).
pef_throw_nde_1(_Context, _Input) ->
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]),
    start_activity(?A_TYPE, [], ?OPTS).

throw_nde_2() ->
    ?assertReplayMatch({error, _}, ?MAIN_EXEC, ?LPATH ++ [throw_2]).
pef_throw_nde_2(_Context, _Input) ->
    start_activity(?A_TYPE, [], ?OPTS),
    #{result := ?DATA} = start_activity(?A_TYPE, ?DATA, [wait | ?OPTS]).

loop() ->
    ?assertReplayEqualF({completed, []}, ?MAIN_EXEC, ?LPATH).
pef_loop(_Context, _Input) ->
    Seq = lists:seq(1, ?LOOP_SIZE),
    AL = [start_activity(?A_TYPE, [I], ?OPTS) || I <- Seq],
    Seq = lists:map(fun(#{result := [R]}) -> R end, wait_all(AL)).

loop_nde_1() ->
    ?assertReplayMatch({error, _}, ?MAIN_EXEC, ?LPATH ++ [loop]).
pef_loop_nde_1(_Context, _Input) ->
    start_activity(?A_TYPE, [], ?OPTS),
    Seq = lists:seq(1, ?LOOP_SIZE),
    AL = [start_activity(?A_TYPE, [I], ?OPTS) || I <- Seq],
    Seq = lists:map(fun(#{result := [R]}) -> R end, wait_all(AL)).

loop_nde_2() ->
    ?assertReplayMatch({error, _}, ?MAIN_EXEC, ?LPATH ++ [loop]).
pef_loop_nde_2(_Context, _Input) ->
    Seq = lists:seq(1, ?LOOP_SIZE),
    AL = [start_activity(?A_TYPE, [I], ?OPTS) || I <- Seq],
    Seq = lists:map(fun(#{result := [R]}) -> R end, wait_all(AL)),
    start_activity(?A_TYPE, [], ?OPTS).

a_cancel_1() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_a_cancel_1(_Context, _Input) ->
    A = start_activity(?A_TYPE, ?DATA, [{heartbeat_timeout, 1_000} | ?OPTS]),
    cancel_activity(A),
    #{cancel_requested := true, state := canceled} = wait(A).

a_cancel_2() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_a_cancel_2(_Context, _Input) ->
    A = start_activity(?A_TYPE, ["ok", 10_000], [{heartbeat_timeout, 1_000} | ?OPTS]),
    #{state := cmd} = wait(setelement(1, A, activity_cmd)),
    #{state := cmd} = wait(setelement(1, A, activity_cmd), 100),
    #{state := scheduled} = wait(setelement(1, A, activity_schedule), 100),
    {noevent, #{state := scheduled}} = await(A, 100),
    #{state := scheduled} = wait(setelement(1, A, activity_schedule)),
    cancel_activity(A),
    #{state := scheduled} = wait(setelement(1, A, activity_cancel_request)),
    #{state := canceled} = wait(A).

a_cancel_3() ->
    ?assertReplayEqualF({completed, []}, ?MAIN_EXEC, ?LPATH).
pef_a_cancel_3(_Context, _Input) ->
    A1 = start_activity(?A_TYPE, [], ?OPTS),
    A2 = start_activity(?A_TYPE, ["ok", 10_000], [{heartbeat_timeout, 1_000} | ?OPTS]),
    [#{state := completed}, #{state := scheduled}] = wait_all([
        A1, setelement(1, A2, activity_schedule)
    ]),
    cancel_activity(A2),
    #{state := canceled} = wait(A2).

a_cancel_3_nde1() ->
    ?assertReplayMatch({error, _}, ?MAIN_EXEC, ?LPATH ++ [a_cancel_3]).
pef_a_cancel_3_nde1(_Context, _Input) ->
    A1 = start_activity(?A_TYPE, [], ?OPTS),
    A2 = start_activity(?A_TYPE, ["ok", 1_000], [{heartbeat_timeout, 1_000} | ?OPTS]),
    [#{state := completed}, #{state := completed}] = wait(A1, A2).

a_cancel_3_nde2() ->
    ?assertReplayMatch({error, _}, ?MAIN_EXEC, ?LPATH ++ [a_cancel_3]).
pef_a_cancel_3_nde2(_Context, _Input) ->
    A1 = start_activity(?A_TYPE, [], ?OPTS),
    _A2 = start_activity(?A_TYPE, ["ok", 10_000], [{heartbeat_timeout, 1_000} | ?OPTS]),
    #{state := completed} = wait(A1),
    A3 = start_activity(?A_TYPE, [], ?OPTS),
    #{state := completed} = wait(A3).

a_cancel_4() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_a_cancel_4(_Context, _Input) ->
    A = start_activity(
        invalid_activity,
        [],
        [{task_queue, "invalid_task_queue"}, {heartbeat_timeout, 1_000}] ++ ?OPTS
    ),
    cancel_activity(A),
    #{cancel_requested := true, state := canceled} = wait(A).

a_cancel_5() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_a_cancel_5(_Context, _Input) ->
    A = start_activity(
        invalid_activity,
        [],
        [{task_queue, "invalid_task_queue"}, {heartbeat_timeout, 1_000}] ++ ?OPTS
    ),
    #{state := scheduled} = wait(setelement(1, A, activity_schedule), 100),
    cancel_activity(A),
    #{state := canceled} = wait(A).

a_cancel_6() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_a_cancel_6(_Context, [IsReplaying]) ->
    A1 = start_activity(?A_TYPE, [], ?OPTS),
    A2 = start_activity(?A_TYPE, ["ok", 10_000], [{heartbeat_timeout, 1_000} | ?OPTS]),
    #{state := completed} = wait(A1),
    ?THROW_ON_REPLAY,
    cancel_activity(A2),
    #{state := canceled} = wait(A2).

a_cancel_loop() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_a_cancel_loop(_Context, _Input) ->
    Seq = lists:seq(1, ?LOOP_SIZE),
    AL1 = [start_activity(?A_TYPE, [I], ?OPTS) || I <- Seq],
    AL2 = [
        start_activity(?A_TYPE, [I, 10_000], [{heartbeat_timeout, 1_000} | ?OPTS])
     || I <- Seq
    ],
    Seq = lists:map(fun(#{result := [R]}) -> R end, wait_all(AL1)),
    [cancel_activity(A) || A <- AL2],
    [] = lists:filter(fun(#{state := canceled}) -> false end, wait_all(AL2)).

long_fail_await() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_long_fail_await(_Context, [IsReplaying]) ->
    A = start_activity(?A_TYPE, ["ok", 100], ?OPTS),
    ?THROW_ON_REPLAY,
    #{state := completed} = wait(A).

a_a() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_a_a(_Context, _Input) ->
    #{state := completed} = start_activity(?A_TYPE, [], [wait | ?OPTS]),
    #{state := completed} = start_activity(?A_TYPE, [], [wait | ?OPTS]).

a_a_err() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_a_a_err(_Context, [IsReplaying]) ->
    #{state := completed} = start_activity(?A_TYPE, [], [wait | ?OPTS]),
    #{state := completed} = start_activity(?A_TYPE, [], [wait | ?OPTS]),
    ?THROW_ON_REPLAY.

a_err_a() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_a_err_a(_Context, [IsReplaying]) ->
    #{state := completed} = start_activity(?A_TYPE, [], [wait | ?OPTS]),
    ?THROW_ON_REPLAY,
    #{state := completed} = start_activity(?A_TYPE, [], [wait | ?OPTS]).

err_a_a() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_err_a_a(_Context, [IsReplaying]) ->
    ?THROW_ON_REPLAY,
    #{state := completed} = start_activity(?A_TYPE, [], [wait | ?OPTS]),
    #{state := completed} = start_activity(?A_TYPE, [], [wait | ?OPTS]).

a_failing_1() ->
    ?assertReplayEqualF({completed, []}, ?MAIN_EXEC, ?LPATH).
pef_a_failing_1(_Context, _Input) ->
    A = start_activity(?A_TYPE, ["ok", 50, 2]),
    #{attempt := 2, state := completed} = wait(A).

a_failing_2() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC, ?LPATH ++ [a_failing_1]).
pef_a_failing_2(_Context, [IsReplaying]) ->
    A = start_activity(?A_TYPE, ["ok", 50, 2]),
    Pid = self(),
    case IsReplaying of
        false -> timer:apply_after(30, fun() -> exit(Pid, test_error) end);
        true -> ok
    end,
    #{attempt := 2, state := completed} = wait(A).

a_failing_3() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_a_failing_3(_Context, [IsReplaying]) ->
    A = start_activity(?A_TYPE, ["ok", 500, 2]),
    wait(setelement(1, A, activity_schedule), 100),
    ?THROW_ON_REPLAY,
    #{attempt := 2, state := completed} = wait(A).

large_data() ->
    ?assertReplayEqual({completed, []}, ?MAIN_EXEC).
pef_large_data(_Context, _Input) ->
    LargeData = binary:copy(~"X", 2_000_000),
    A = start_activity(?A_TYPE, [LargeData], ?OPTS),
    #{result := _} = wait(A).

-endif.
