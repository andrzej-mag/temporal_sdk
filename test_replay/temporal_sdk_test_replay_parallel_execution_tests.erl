-module(temporal_sdk_test_replay_parallel_execution_tests).

-ifdef(TEST).

-export([echo_execution/2]).

-include_lib("eunit/include/eunit.hrl").
-include("test_replay/include/temporal_sdk_test_replay_fixtures.hrl").

-define(TESTS, [
    fun base/0
]).

base_test_() -> ?FIXTURE(?CONFIGS, {inparallel, {timeout, 10, ?TESTS}}).

echo_execution(_Context, Input) -> Input.

base() ->
    EFn = fun(_Context, _Input) ->
        E = start_execution(?MODULE, echo_execution, {test, input}, []),
        #{state := completed, result := {test, input}} = wait(E)
    end,
    ?assertReplayEqual({completed, []}, EFn).

-endif.
