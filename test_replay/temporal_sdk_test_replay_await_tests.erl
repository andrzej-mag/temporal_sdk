-module(temporal_sdk_test_replay_await_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
-include("test_replay/include/temporal_sdk_test_replay_fixtures.hrl").

-define(TESTS, [
    fun test_is_awaited/0,
    fun test_await_all/0,
    fun test_await_all_events/0,
    fun test_await_one/0,
    fun test_await_one_events/0,
    fun test_await_all_all/0,
    fun test_await_one_one/0,
    fun test_await_all_one/0,
    fun test_await_one_all/0,
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
        {false, {one, [noevent, noevent, noevent]}} = is_awaited({one, [A, T, I]}),
        {false, [noevent, noevent, noevent]} = is_awaited_one([A, T, I]),

        ?StD = wait(setelement(1, A, activity_cmd)),
        {false, ?StD} = is_awaited(A),
        {false, ?StD} = is_awaited(T),
        {false, noevent} = is_awaited(I),
        {false, {all, [?StD, ?StD, noevent]}} = is_awaited({all, [A, T, I]}),
        {false, [?StD, ?StD, noevent]} = is_awaited_all([A, T, I]),
        {false, {one, [?StD, ?StD, noevent]}} = is_awaited({one, [A, T, I]}),
        {false, [?StD, ?StD, noevent]} = is_awaited_one([A, T, I]),

        [?StC, ?StF] = wait_all([A, T]),
        {true, ?StC} = is_awaited(A),
        {true, ?StF} = is_awaited(T),
        {false, noevent} = is_awaited(I),
        {false, {all, [?StC, ?StF, noevent]}} = is_awaited({all, [A, T, I]}),
        {false, [?StC, ?StF, noevent]} = is_awaited_all([A, T, I]),
        {true, {all, [?StC, ?StF]}} = is_awaited({all, [A, T]}),
        {true, [?StC, ?StF]} = is_awaited_all([A, T]),
        {true, {one, [?StC, ?StF, noevent]}} = is_awaited({one, [A, T, I]}),
        {true, [?StC, ?StF, noevent]} = is_awaited_one([A, T, I])
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

test_await_one() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        case IsReplaying of
            false ->
                {ok, [?StC, ?StS]} = await_one([A, T]),
                [?StC, ?StS] = wait_one([A, T]),
                {ok, {one, [?StC, ?StS]}} =
                    await({one, [A, T]}),
                {ok, {one, [?StC, ?StS, ?StC, ?StS]}} =
                    await({one, [A, T, A, T]}),
                {ok, {one, [{one, [?StC, ?StS, ?StC, ?StS]}]}} =
                    await({one, [{one, [A, T, A, T]}]}),
                {ok, {one, [{one, [{one, [?StC, ?StS, ?StC, ?StS]}]}]}} =
                    await({one, [{one, [{one, [A, T, A, T]}]}]}),
                {ok, {one, [{one, [{one, [{one, [?StC, ?StS, ?StC, ?StS]}]}]}]}} =
                    await({one, [{one, [{one, [{one, [A, T, A, T]}]}]}]});
            true ->
                {ok, [?StC, ?StF]} = await_one([A, T]),
                [?StC, ?StF] = wait_one([A, T]),
                {ok, {one, [?StC, ?StF]}} =
                    await({one, [A, T]}),
                {ok, {one, [?StC, ?StF, ?StC, ?StF]}} =
                    await({one, [A, T, A, T]}),
                {ok, {one, [{one, [?StC, ?StF, ?StC, ?StF]}]}} =
                    await({one, [{one, [A, T, A, T]}]}),
                {ok, {one, [{one, [{one, [?StC, ?StF, ?StC, ?StF]}]}]}} =
                    await({one, [{one, [{one, [A, T, A, T]}]}]}),
                {ok, {one, [{one, [{one, [{one, [?StC, ?StF, ?StC, ?StF]}]}]}]}} =
                    await({one, [{one, [{one, [{one, [A, T, A, T]}]}]}]})
        end
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_one_events() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        {ok, {one, [?StD, ?StD]}} =
            await({one, [setelement(1, A, activity_cmd), setelement(1, T, timer_cmd)]}),
        case IsReplaying of
            false ->
                {ok, {one, [?StC, ?StS]}} =
                    await(
                        {one, [setelement(1, A, activity_schedule), setelement(1, T, timer_start)]}
                    ),
                {ok, {one, [?StC, ?StS]}} =
                    await({one, [setelement(1, A, activity_start), setelement(1, T, timer_start)]});
            true ->
                {ok, {one, [?StC, ?StF]}} =
                    await(
                        {one, [setelement(1, A, activity_schedule), setelement(1, T, timer_start)]}
                    ),
                {ok, {one, [?StC, ?StF]}} =
                    await({one, [setelement(1, A, activity_start), setelement(1, T, timer_start)]})
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

test_await_one_one() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        case IsReplaying of
            false ->
                {ok, {one, [{one, [?StC, ?StS]}, {one, [?StC, ?StS]}]}} =
                    await({one, [{one, [A, T]}, {one, [A, T]}]}),
                {ok, {one, [{one, [?StC, ?StS, ?StC, ?StS]}, {one, [?StC, ?StS, ?StC, ?StS]}]}} =
                    await({one, [{one, [A, T, A, T]}, {one, [A, T, A, T]}]});
            true ->
                {ok, {one, [{one, [?StC, ?StF]}, {one, [?StC, ?StF]}]}} =
                    await({one, [{one, [A, T]}, {one, [A, T]}]}),
                {ok, {one, [{one, [?StC, ?StF, ?StC, ?StF]}, {one, [?StC, ?StF, ?StC, ?StF]}]}} =
                    await({one, [{one, [A, T, A, T]}, {one, [A, T, A, T]}]})
        end
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_all_one() ->
    EFn = fun(#{is_replaying := IsReplaying}, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        case IsReplaying of
            false ->
                {ok, {all, [{one, [?StC, ?StS]}, {one, [?StC, ?StS]}]}} =
                    await({all, [{one, [A, T]}, {one, [A, T]}]}),
                {ok, {all, [{all, [?StC, ?StF]}, {one, [?StC, ?StF]}]}} =
                    await({all, [{all, [A, T]}, {one, [A, T]}]});
            true ->
                {ok, {all, [{one, [?StC, ?StF]}, {one, [?StC, ?StF]}]}} =
                    await({all, [{one, [A, T]}, {one, [A, T]}]}),
                {ok, {all, [{all, [?StC, ?StF]}, {one, [?StC, ?StF]}]}} =
                    await({all, [{all, [A, T]}, {one, [A, T]}]})
        end
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_one_all() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        {ok, {one, [{all, [?StC, ?StF]}, {all, [?StC, ?StF]}]}} =
            await({one, [{all, [A, T]}, {all, [A, T]}]}),
        {ok, {one, [{all, [?StC, ?StF]}, {one, [?StC, ?StF]}]}} =
            await({one, [{all, [A, T]}, {one, [A, T]}]})
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_timeout_1() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        {ok, {one, [?StC, ?StS]}} = await({one, [A, T]}, round(?TTO / 4)),
        {ok, {all, [?StC, ?StF]}} = await({all, [A, T]}, round(?TTO / 4)),
        {ok, {one, [?StC, ?StF]}} = await({one, [A, T]}, round(?TTO / 4))
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_wait_timeout_1() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        {one, [?StC, ?StS]} = wait({one, [A, T]}, round(?TTO / 4)),
        {all, [?StC, ?StF]} = wait({all, [A, T]}, round(?TTO / 4)),
        {one, [?StC, ?StF]} = wait({one, [A, T]}, round(?TTO / 4))
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_timeout_2() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        {ok, [?StC, ?StS]} = await_one([A, T], round(?TTO / 4)),
        {ok, [?StC, ?StF]} = await_all([A, T], round(?TTO / 4)),
        {ok, [?StC, ?StF]} = await_one([A, T], round(?TTO / 4))
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_wait_timeout_2() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        [?StC, ?StS] = wait_one([A, T], round(?TTO / 4)),
        [?StC, ?StF] = wait_all([A, T], round(?TTO / 4)),
        [?StC, ?StF] = wait_one([A, T], round(?TTO / 4))
    end,
    ?assertReplayEqual({completed, []}, EFn).

test_await_noevent() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, []),
        T = start_timer(?TTO),
        M = {marker, none, invalid},
        {ok, {one, [?StC, ?StS, noevent]}} = await({one, [A, T, M]}),
        {ok, {one, [?StC, ?StS, noevent]}} = await({one, [A, T, M]}, round(?TTO / 4)),
        {noevent, {all, [?StC, ?StF, noevent]}} = await({all, [A, T, M]}, round(?TTO / 4)),
        {noevent, {all, [?StC, ?StF, noevent]}} = await({all, [A, T, M]}),
        {ok, {one, [?StC, ?StF, noevent]}} = await({one, [A, T, M]}, round(?TTO / 4)),
        {ok, {one, [?StC, ?StF, noevent]}} = await({one, [A, T, M]})
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
        ?assertError(noevent, wait_one([I])),
        ?assertError(noevent, wait_one([I], 1_000))
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
        set_info({one, [A, T, M]}, [{info_id, test_info_one}]),
        {noevent, {all, [?StC, ?StF, noevent]}} = await_info(test_info_all),
        {noevent, {all, [?StC, ?StF, noevent]}} = await_info(test_info_all, 1, 1),
        {ok, {one, [?StC, ?StF, noevent]}} = await_info(test_info_one),
        {ok, {one, [?StC, ?StF, noevent]}} = await_info(test_info_one, 1, 1)
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
        set_info({one, [A, T, M]}, [{info_id, test_info_one}]),
        ?assertError(noevent, wait_info(test_info_all)),
        ?assertError(noevent, wait_info(test_info_all, 1, 1)),
        {one, [?StC, ?StF, noevent]} = wait_info(test_info_one),
        {one, [?StC, ?StF, noevent]} = wait_info(test_info_one, 1, 1)
    end,
    ?assertReplayEqual({completed, []}, EFn).

-endif.
