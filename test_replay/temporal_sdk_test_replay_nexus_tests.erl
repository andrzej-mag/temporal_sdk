-module(temporal_sdk_test_replay_nexus_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
-include("test_replay/include/temporal_sdk_test_replay_fixtures.hrl").

-define(TESTS, [
    fun base/0
]).

base_test_() -> ?FIXTURE(?CONFIGS, {inparallel, {timeout, 10, ?TESTS}}).

base() ->
    EFn = fun(_Context, _Input) ->
        ok
    end,
    ?assertReplayEqual({completed, []}, EFn).

-endif.
