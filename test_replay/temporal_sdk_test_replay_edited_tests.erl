-module(temporal_sdk_test_replay_edited_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
-include("test_replay/include/temporal_sdk_test_replay_fixtures.hrl").

-define(TESTS, [
    % fun gen_base/0,
    % fun gen_missing_activity_started/0
    fun missing_completed/0,
    fun missing_1/0,
    fun missing_3/0,
    fun duplicate/0,
    fun duplicate_complete/0,
    fun out_of_order/0,
    fun unknown/0,
    fun missing_activity_started/0
]).

-define(LPATH, [json_edited, ?FUNCTION_NAME]).

base_test_() -> ?FIXTURE(?CONFIGS, {inparallel, {timeout, 10, ?TESTS}}).

% gen_base() ->
%     EFn = fun(_Context, _Input) -> ok end,
%     ?assertReplayEqualF({completed, []}, EFn, [json_edited]).
%
% gen_missing_activity_started() ->
%     EFn = fun(_Context, _Input) ->
%         A = start_activity(?A_TYPE, ["string", ~"binary", 123]),
%         #{result := ["string", ~"binary", 123]} = wait(A)
%     end,
%     ?assertReplayEqualF({completed, []}, EFn, [json_edited]).

missing_completed() ->
    EFn = fun(_Context, _Input) -> ok end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH).

missing_1() ->
    EFn = fun(_Context, _Input) -> ok end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH).

missing_3() ->
    EFn = fun(_Context, _Input) -> ok end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH).

duplicate() ->
    EFn = fun(_Context, _Input) -> ok end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH).

out_of_order() ->
    EFn = fun(_Context, _Input) -> ok end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH).

duplicate_complete() ->
    EFn = fun(_Context, _Input) -> ok end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH).

unknown() ->
    EFn = fun(_Context, _Input) -> ok end,
    ?assertReplayEqual({completed, []}, EFn, ?LPATH).

missing_activity_started() ->
    EFn = fun(_Context, _Input) ->
        A = start_activity(?A_TYPE, ["string", ~"binary", 123]),
        #{result := ["string", ~"binary", 123]} = wait(A)
    end,
    ?assertReplayMatch({error, _}, EFn, ?LPATH).

-endif.
