-module(temporal_sdk_test_replay_signal_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
-include("test_replay/include/temporal_sdk_test_replay_fixtures.hrl").

-define(TESTS, [
    fun base/0
]).

base_test_() -> ?FIXTURE(?CONFIGS, {inparallel, {timeout, 10, ?TESTS}}).

-define(SIN, ~"test_signal").

-define(SIGNAL(),
    case IsReplaying of
        false ->
            spawn(fun() ->
                temporal_sdk_service:signal_workflow(?CL, WE, ?SIN, [{namespace, ?NS}])
            end);
        true ->
            ok
    end
).

base() ->
    EFn = fun(#{is_replaying := IsReplaying, workflow_info := #{workflow_execution := WE}}, _Input) ->
        ?SIGNAL(),
        start_timer(500),
        ?assertMatch(#{state := requested}, wait({signal, ?SIN})),
        ?assertMatch({noevent, noevent}, await({signal, ~"invalid"}))
    end,
    ?assertReplayEqual({completed, []}, EFn).

-endif.
