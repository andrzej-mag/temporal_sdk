-module(temporal_sdk_test_replay_misc_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
-include("test_replay/include/temporal_sdk_test_replay_fixtures.hrl").

-define(TESTS, [
    fun activity_canceled_timer/0,
    fun events_iterator/0
]).

base_test_() -> ?FIXTURE(?CONFIGS, {inparallel, {timeout, 10, ?TESTS}}).

activity_canceled_timer() ->
    EFn = fun(_Context, _Input) ->
        {noevent, noevent} = await({marker, none, invalid}),
        A = start_activity(?A_TYPE, ?DATA),
        #{state := cmd} = wait(setelement(1, A, activity_cmd), 10_000),
        {noevent, noevent} = await({marker, none, invalid}),
        #{state := completed, result := ?DATA} = wait(A),
        {noevent, noevent} = await({marker, none, invalid})
    end,
    ?assertReplayEqual({completed, []}, EFn).

events_iterator() ->
    EFn = fun(_Context, _Input) ->
        start_activity(?A_TYPE, []),
        record_uuid4(),
        EventsCount = do_events_iterator(1),
        set_workflow_result([EventsCount])
    end,
    ?assertReplayEqual({completed, [12]}, EFn).

do_events_iterator(EventId) ->
    case await({event, {EventId, '_', '_', '_'}}) of
        {noevent, noevent} -> EventId;
        {ok, #{event_id := EventId}} -> do_events_iterator(EventId + 1)
    end.

-endif.
