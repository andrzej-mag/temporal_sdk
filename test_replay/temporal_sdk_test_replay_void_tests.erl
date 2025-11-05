-module(temporal_sdk_test_replay_void_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
-include("test_replay/include/temporal_sdk_test_replay_fixtures.hrl").

-define(TESTS, [
    fun base/0,
    fun base_noevent/0,
    fun base_nde/0,
    fun complete/0,
    fun complete_noevent/0,
    fun complete_noevent_noevent/0,
    fun complete_nde/0,
    fun complete_prohibited_nde/0,
    fun cancel/0,
    fun cancel_noevent/0,
    fun cancel_nde/0,
    fun cancel_prohibited_nde/0,
    fun fail/0,
    fun fail_noevent/0,
    fun fail_nde/0,
    fun fail_prohibited_nde/0,
    fun throw/0,
    fun throw_nde/0
]).

-define(LPATH, [json, void]).

base_test_() -> ?FIXTURE(?CONFIGS, {inparallel, {timeout, 10, ?TESTS}}).

base() ->
    EFn = fun(_Context, _Input) ->
        ok
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

base_noevent() ->
    EFn = fun(_Context, _Input) ->
        {noevent, noevent} = await({marker, none, invalid})
    end,
    ?assertReplayEqual({completed, []}, EFn, ?LPATH ++ [base]).

base_nde() ->
    EFn = fun(_Context, _Input) ->
        start_activity(?A_TYPE, [])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [base]).

complete() ->
    EFn = fun(_Context, _Input) ->
        complete_workflow_execution([])
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

complete_noevent() ->
    EFn = fun(_Context, _Input) ->
        {noevent, noevent} = await({marker, none, invalid}),
        complete_workflow_execution([])
    end,
    ?assertReplayEqual({completed, []}, EFn, ?LPATH ++ [complete]).

complete_noevent_noevent() ->
    EFn = fun(_Context, _Input) ->
        {noevent, noevent} = await({marker, none, invalid}),
        {noevent, noevent} = await({marker, none, invalid}),
        complete_workflow_execution([])
    end,
    ?assertReplayEqual({completed, []}, EFn, ?LPATH ++ [complete]).

complete_nde() ->
    EFn = fun(_Context, _Input) ->
        start_activity(?A_TYPE, []),
        complete_workflow_execution([])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [complete]).

complete_prohibited_nde() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        complete_workflow_execution(?DATA),
        case IsReplaying of
            false -> start_activity(?A_TYPE, []);
            true -> set_workflow_result(?DATA)
        end
    end,
    ?assertReplayEqual({completed, ?DATA}, EFn, ?LPATH ++ [complete]).

cancel() ->
    EFn = fun(_Context, _Input) ->
        cancel_workflow_execution([])
    end,
    ?assertReplayEqualF({canceled, []}, EFn, ?LPATH).

cancel_noevent() ->
    EFn = fun(_Context, _Input) ->
        {noevent, noevent} = await({marker, none, invalid}),
        cancel_workflow_execution([])
    end,
    ?assertReplayEqual({canceled, []}, EFn, ?LPATH ++ [cancel]).

cancel_nde() ->
    EFn = fun(_Context, _Input) ->
        start_activity(?A_TYPE, []),
        cancel_workflow_execution([])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [cancel]).

cancel_prohibited_nde() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        cancel_workflow_execution(?DATA),
        case IsReplaying of
            false -> start_activity(?A_TYPE, []);
            true -> set_workflow_result(?DATA)
        end
    end,
    ?assertReplayEqual({canceled, ?DATA}, EFn, ?LPATH ++ [cancel]).

fail() ->
    EFn = fun(_Context, _Input) ->
        fail_workflow_execution(#{source => "Src", message => "Msg", stack_trace => "ST"})
    end,
    ?assertReplayMatchF(
        {failed, #{source := "Src", message := "Msg", stack_trace := "ST"}},
        EFn,
        ?LPATH
    ).

fail_noevent() ->
    EFn = fun(_Context, _Input) ->
        {noevent, noevent} = await({marker, none, invalid}),
        fail_workflow_execution(#{source => "Src", message => "Msg", stack_trace => "ST"})
    end,
    ?assertReplayMatch(
        {failed, #{source := "Src", message := "Msg", stack_trace := "ST"}},
        EFn,
        ?LPATH ++ [fail]
    ).

fail_nde() ->
    EFn = fun(_Context, _Input) ->
        start_activity(?A_TYPE, []),
        fail_workflow_execution(#{source => "Src", message => "Msg", stack_trace => "ST"})
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [fail]).

fail_prohibited_nde() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
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

throw() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        case IsReplaying of
            false -> throw(test_error);
            true -> ok
        end
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

throw_nde() ->
    EFn = fun(_Context, _Input) ->
        start_activity(?A_TYPE, [])
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [throw]).

-endif.
