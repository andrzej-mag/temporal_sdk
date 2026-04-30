-module(temporal_sdk_test_replay_await_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
-include("test_replay/include/temporal_sdk_test_replay_fixtures.hrl").

-define(TESTS, [
    fun test_is_awaited/0,
    fun test_await_all/0,
    fun test_await_all_events/0,
    fun test_await_any/0,
    fun test_await_any_events/0,
    fun test_await_all_all/0,
    fun test_await_any_any/0,
    fun test_await_all_any/0,
    fun test_await_any_all/0,
    fun test_await_timeout_1/0,
    fun test_wait_timeout_1/0,
    fun test_await_timeout_2/0,
    fun test_wait_timeout_2/0,
    fun test_await_noevent/0,
    fun await_timeout_nde_1_base/0,
    fun await_timeout_nde_1/0,
    fun await_timeout_nde_2_base/0,
    fun await_timeout_nde_2/0,
    fun await_timeout_timer/0,
    fun raising_wait/0,
    {timeout, 9, fun test_await_info/0},
    {timeout, 9, fun test_wait_info/0}
]).

base_test_() -> ?FIXTURE(?CONFIGS, {inparallel, {timeout, 10, ?TESTS}}).
-define(LPATH, [json, await]).

-define(TTO, 500).

-define(StD, #{state := cmd}).
-define(StS, #{state := started}).
-define(StC, #{state := completed}).
-define(StF, #{state := fired}).

test_is_awaited() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        I = {marker, none, invalid},
        {false, noevent} = is_awaited(A),
        {false, noevent} = is_awaited(T),
        {false, noevent} = is_awaited(I),
        {false, {all, [noevent, noevent, noevent]}} = is_awaited({all, [A, T, I]}),
        {false, [noevent, noevent, noevent]} = is_awaited_all([A, T, I]),
        {false, {any, [noevent, noevent, noevent]}} = is_awaited({any, [A, T, I]}),
        {false, [noevent, noevent, noevent]} = is_awaited_any([A, T, I]),

        ?StD = wait(setelement(1, A, activity_cmd)),
        {false, ?StD} = is_awaited(A),
        {false, ?StD} = is_awaited(T),
        {false, noevent} = is_awaited(I),
        {false, {all, [?StD, ?StD, noevent]}} = is_awaited({all, [A, T, I]}),
        {false, [?StD, ?StD, noevent]} = is_awaited_all([A, T, I]),
        {false, {any, [?StD, ?StD, noevent]}} = is_awaited({any, [A, T, I]}),
        {false, [?StD, ?StD, noevent]} = is_awaited_any([A, T, I]),

        [?StC, ?StF] = wait_all([A, T]),
        {true, ?StC} = is_awaited(A),
        {true, ?StF} = is_awaited(T),
        {false, noevent} = is_awaited(I),
        {false, {all, [?StC, ?StF, noevent]}} = is_awaited({all, [A, T, I]}),
        {false, [?StC, ?StF, noevent]} = is_awaited_all([A, T, I]),
        {true, {all, [?StC, ?StF]}} = is_awaited({all, [A, T]}),
        {true, [?StC, ?StF]} = is_awaited_all([A, T]),
        {true, {any, [?StC, ?StF, noevent]}} = is_awaited({any, [A, T, I]}),
        {true, [?StC, ?StF, noevent]} = is_awaited_any([A, T, I])
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_all() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        {ok, [?StC, ?StF]} = await_all([A, T]),
        [?StC, ?StF] = wait_all([A, T]),
        {ok, {all, [?StC, ?StF]}} =
            await({all, [A, T]}),
        {ok, {all, [?StC, ?StF, ?StC, ?StF]}} =
            await({all, [A, T, A, T]}),
        {ok, {all, [{all, [?StC, ?StF, ?StC, ?StF]}]}} =
            await({all, [{all, [A, T, A, T]}]}),
        {ok, {all, [{all, [{all, [?StC, ?StF, ?StC, ?StF]}]}]}} =
            await({all, [{all, [{all, [A, T, A, T]}]}]}),
        {ok, {all, [{all, [{all, [{all, [?StC, ?StF, ?StC, ?StF]}]}]}]}} =
            await({all, [{all, [{all, [{all, [A, T, A, T]}]}]}]})
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_all_events() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        {ok, {all, [?StD, ?StD]}} =
            await({all, [setelement(1, A, activity_cmd), setelement(1, T, timer_cmd)]}),
        case IsReplaying of
            false ->
                {ok, {all, [?StC, ?StS]}} =
                    await(
                        {all, [setelement(1, A, activity_schedule), setelement(1, T, timer_cmd)]}
                    ),
                {ok, {all, [?StC, ?StS]}} =
                    await({all, [setelement(1, A, activity_start), setelement(1, T, timer_cmd)]});
            true ->
                {ok, {all, [?StC, ?StF]}} =
                    await(
                        {all, [setelement(1, A, activity_schedule), setelement(1, T, timer_cmd)]}
                    ),
                {ok, {all, [?StC, ?StF]}} =
                    await({all, [setelement(1, A, activity_start), setelement(1, T, timer_cmd)]})
        end
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_any() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        case IsReplaying of
            false ->
                {ok, [?StC, ?StS]} = await_any([A, T]),
                [?StC, ?StS] = wait_any([A, T]),
                {ok, {any, [?StC, ?StS]}} =
                    await({any, [A, T]}),
                {ok, {any, [?StC, ?StS, ?StC, ?StS]}} =
                    await({any, [A, T, A, T]}),
                {ok, {any, [{any, [?StC, ?StS, ?StC, ?StS]}]}} =
                    await({any, [{any, [A, T, A, T]}]}),
                {ok, {any, [{any, [{any, [?StC, ?StS, ?StC, ?StS]}]}]}} =
                    await({any, [{any, [{any, [A, T, A, T]}]}]}),
                {ok, {any, [{any, [{any, [{any, [?StC, ?StS, ?StC, ?StS]}]}]}]}} =
                    await({any, [{any, [{any, [{any, [A, T, A, T]}]}]}]});
            true ->
                {ok, [?StC, ?StF]} = await_any([A, T]),
                [?StC, ?StF] = wait_any([A, T]),
                {ok, {any, [?StC, ?StF]}} =
                    await({any, [A, T]}),
                {ok, {any, [?StC, ?StF, ?StC, ?StF]}} =
                    await({any, [A, T, A, T]}),
                {ok, {any, [{any, [?StC, ?StF, ?StC, ?StF]}]}} =
                    await({any, [{any, [A, T, A, T]}]}),
                {ok, {any, [{any, [{any, [?StC, ?StF, ?StC, ?StF]}]}]}} =
                    await({any, [{any, [{any, [A, T, A, T]}]}]}),
                {ok, {any, [{any, [{any, [{any, [?StC, ?StF, ?StC, ?StF]}]}]}]}} =
                    await({any, [{any, [{any, [{any, [A, T, A, T]}]}]}]})
        end
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_any_events() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        {ok, {any, [?StD, ?StD]}} =
            await({any, [setelement(1, A, activity_cmd), setelement(1, T, timer_cmd)]}),
        case IsReplaying of
            false ->
                {ok, {any, [?StC, ?StS]}} =
                    await(
                        {any, [setelement(1, A, activity_schedule), setelement(1, T, timer_start)]}
                    ),
                {ok, {any, [?StC, ?StS]}} =
                    await({any, [setelement(1, A, activity_start), setelement(1, T, timer_start)]});
            true ->
                {ok, {any, [?StC, ?StF]}} =
                    await(
                        {any, [setelement(1, A, activity_schedule), setelement(1, T, timer_start)]}
                    ),
                {ok, {any, [?StC, ?StF]}} =
                    await({any, [setelement(1, A, activity_start), setelement(1, T, timer_start)]})
        end
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_all_all() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        {ok, {all, [{all, [?StC, ?StF]}, {all, [?StC, ?StF]}]}} =
            await({all, [{all, [A, T]}, {all, [A, T]}]}),
        {ok, {all, [{all, [?StC, ?StF, ?StC, ?StF]}, {all, [?StC, ?StF, ?StC, ?StF]}]}} =
            await({all, [{all, [A, T, A, T]}, {all, [A, T, A, T]}]})
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_any_any() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        case IsReplaying of
            false ->
                {ok, {any, [{any, [?StC, ?StS]}, {any, [?StC, ?StS]}]}} =
                    await({any, [{any, [A, T]}, {any, [A, T]}]}),
                {ok, {any, [{any, [?StC, ?StS, ?StC, ?StS]}, {any, [?StC, ?StS, ?StC, ?StS]}]}} =
                    await({any, [{any, [A, T, A, T]}, {any, [A, T, A, T]}]});
            true ->
                {ok, {any, [{any, [?StC, ?StF]}, {any, [?StC, ?StF]}]}} =
                    await({any, [{any, [A, T]}, {any, [A, T]}]}),
                {ok, {any, [{any, [?StC, ?StF, ?StC, ?StF]}, {any, [?StC, ?StF, ?StC, ?StF]}]}} =
                    await({any, [{any, [A, T, A, T]}, {any, [A, T, A, T]}]})
        end
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_all_any() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        case IsReplaying of
            false ->
                {ok, {all, [{any, [?StC, ?StS]}, {any, [?StC, ?StS]}]}} =
                    await({all, [{any, [A, T]}, {any, [A, T]}]}),
                {ok, {all, [{all, [?StC, ?StF]}, {any, [?StC, ?StF]}]}} =
                    await({all, [{all, [A, T]}, {any, [A, T]}]});
            true ->
                {ok, {all, [{any, [?StC, ?StF]}, {any, [?StC, ?StF]}]}} =
                    await({all, [{any, [A, T]}, {any, [A, T]}]}),
                {ok, {all, [{all, [?StC, ?StF]}, {any, [?StC, ?StF]}]}} =
                    await({all, [{all, [A, T]}, {any, [A, T]}]})
        end
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_any_all() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        {ok, {any, [{all, [?StC, ?StF]}, {all, [?StC, ?StF]}]}} =
            await({any, [{all, [A, T]}, {all, [A, T]}]}),
        {ok, {any, [{all, [?StC, ?StF]}, {any, [?StC, ?StF]}]}} =
            await({any, [{all, [A, T]}, {any, [A, T]}]})
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_timeout_1() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        {ok, {any, [?StC, ?StS]}} = await({any, [A, T]}, round(?TTO / 4)),
        {ok, {all, [?StC, ?StF]}} = await({all, [A, T]}, round(?TTO / 4)),
        {ok, {any, [?StC, ?StF]}} = await({any, [A, T]}, round(?TTO / 4))
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_wait_timeout_1() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        {any, [?StC, ?StS]} = wait({any, [A, T]}, round(?TTO / 4)),
        {all, [?StC, ?StF]} = wait({all, [A, T]}, round(?TTO / 4)),
        {any, [?StC, ?StF]} = wait({any, [A, T]}, round(?TTO / 4))
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_timeout_2() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        {ok, [?StC, ?StS]} = await_any([A, T], round(?TTO / 4)),
        {ok, [?StC, ?StF]} = await_all([A, T], round(?TTO / 4)),
        {ok, [?StC, ?StF]} = await_any([A, T], round(?TTO / 4))
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_wait_timeout_2() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        [?StC, ?StS] = wait_any([A, T], round(?TTO / 4)),
        [?StC, ?StF] = wait_all([A, T], round(?TTO / 4)),
        [?StC, ?StF] = wait_any([A, T], round(?TTO / 4))
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_noevent() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        M = {marker, none, invalid},
        {ok, {any, [?StC, ?StS, noevent]}} = await({any, [A, T, M]}),
        {ok, {any, [?StC, ?StS, noevent]}} = await({any, [A, T, M]}, round(?TTO / 4)),
        {noevent, {all, [?StC, ?StF, noevent]}} = await({all, [A, T, M]}, round(?TTO / 4)),
        {noevent, {all, [?StC, ?StF, noevent]}} = await({all, [A, T, M]}),
        {ok, {any, [?StC, ?StF, noevent]}} = await({any, [A, T, M]}, round(?TTO / 4)),
        {ok, {any, [?StC, ?StF, noevent]}} = await({any, [A, T, M]})
    end,
    ?assertReplayEqual({completed, []}, EFn).

await_timeout_nde_1_base() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, [?DATA, 1_000]),
        {ok, #{result := ?DATA}} = await(A, 2_000)
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

await_timeout_nde_1() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, [?DATA, 1_000]),
        {ok, #{result := ?DATA}} = await(A)
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [await_timeout_nde_1_base]).

await_timeout_nde_2_base() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, [?DATA, 1_000]),
        {ok, #{result := ?DATA}} = await(A)
    end,
    ?assertReplayEqualF({completed, []}, EFn, ?LPATH).

await_timeout_nde_2() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, [?DATA, 1_000]),
        {ok, #{result := ?DATA}} = await(A, 2000)
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH ++ [await_timeout_nde_2_base]).

await_timeout_timer() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, [?DATA, 1_000]),
        {ok, #{state := completed}} = await(A, 2_000),
        ?assertMatch([{_, #{}}], select_index({{timer, '_'}, #{}}))
    end,
    ?assertReplayEqual({completed, []}, EFn).

raising_wait() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        I = {marker, none, invalid},
        ?assertError(noevent, wait(I)),
        ?assertError(noevent, wait(I, 1_000)),
        ?assertError(noevent, wait_all([A, T, I])),
        ?assertError(noevent, wait_all([A, T, I], 1_000)),
        ?assertError(noevent, wait_any([I])),
        ?assertError(noevent, wait_any([I], 1_000))
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_info() ->
    EFn = fun(_Context, _Input) ->
        noinfo = await_info(test_info),
        noinfo = await_info(test_info, 1, 1),
        noinfo = await_info(test_info, {1, millisecond}, 1),
        noinfo = await_info(test_info, 1, {1, millisecond}),
        noinfo = await_info(test_info, {1, millisecond}, {1, millisecond}),

        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        M = {marker, none, invalid},
        set_info(A, [{info_id, test_info_a}]),
        set_info(T, [{info_id, test_info_t}]),
        set_info(M, [{info_id, test_info_m}]),
        {ok, ?StC} = await_info(test_info_a),
        {ok, ?StC} = await_info(test_info_a, 1, 1),
        {ok, ?StF} = await_info(test_info_t),
        {ok, ?StF} = await_info(test_info_t, 1, 1),
        {noevent, noevent} = await_info(test_info_m),
        {noevent, noevent} = await_info(test_info_m, 1, 1),

        set_info({all, [A, T, M]}, [{info_id, test_info_all}]),
        set_info({any, [A, T, M]}, [{info_id, test_info_any}]),
        {noevent, {all, [?StC, ?StF, noevent]}} = await_info(test_info_all),
        {noevent, {all, [?StC, ?StF, noevent]}} = await_info(test_info_all, 1, 1),
        {ok, {any, [?StC, ?StF, noevent]}} = await_info(test_info_any),
        {ok, {any, [?StC, ?StF, noevent]}} = await_info(test_info_any, 1, 1)
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_wait_info() ->
    EFn = fun(_Context, _Input) ->
        ?assertError(noinfo, wait_info(test_info)),
        ?assertError(noinfo, wait_info(test_info, 1, 1)),
        ?assertError(noinfo, wait_info(test_info, {1, millisecond}, 1)),
        ?assertError(noinfo, wait_info(test_info, 1, {1, millisecond})),
        ?assertError(noinfo, wait_info(test_info, {1, millisecond}, {1, millisecond})),

        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        M = {marker, none, invalid},
        set_info(A, [{info_id, test_info_a}]),
        set_info(T, [{info_id, test_info_t}]),
        set_info(M, [{info_id, test_info_m}]),
        ?StC = wait_info(test_info_a),
        ?StC = wait_info(test_info_a, 1, 1),
        ?StF = wait_info(test_info_t),
        ?StF = wait_info(test_info_t, 1, 1),
        ?assertError(noevent, wait_info(test_info_m)),
        ?assertError(noevent, wait_info(test_info_m, 1, 1)),

        set_info({all, [A, T, M]}, [{info_id, test_info_all}]),
        set_info({any, [A, T, M]}, [{info_id, test_info_any}]),
        ?assertError(noevent, wait_info(test_info_all)),
        ?assertError(noevent, wait_info(test_info_all, 1, 1)),
        {any, [?StC, ?StF, noevent]} = wait_info(test_info_any),
        {any, [?StC, ?StF, noevent]} = wait_info(test_info_any, 1, 1)
    end,
    ?assertReplayEqual({completed, []}, EFn).

-endif.
