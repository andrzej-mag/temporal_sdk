-module(temporal_sdk_utils_recycled_int_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-import(temporal_sdk_utils_recycled_int, [
    start_link/2,
    new/1,
    recycle/1
]).

-define(MSG_TAG, msg_tag).

basic_test() ->
    ?assertMatch({ok, _Pid}, start_link(?MODULE, ?MSG_TAG)),
    Pid = self(),

    ?assertEqual(ok, new(?MODULE)),
    receive
        {?MSG_TAG, {recycled_integer, Int1}} -> ?assertEqual(1, Int1)
    end,

    spawn(fun() ->
        ?assertEqual(ok, new(?MODULE)),
        receive
            {?MSG_TAG, {recycled_integer, Int2}} -> Pid ! {?MSG_TAG, Int2}
        end
    end),
    receive
        {?MSG_TAG, Int3} -> ?assertEqual(2, Int3)
    end,

    spawn(fun() ->
        ?assertEqual(ok, new(?MODULE)),
        receive
            {?MSG_TAG, {recycled_integer, Int4}} -> Pid ! {?MSG_TAG, Int4}
        end
    end),
    receive
        {?MSG_TAG, Int5} -> ?assertEqual(2, Int5)
    end,

    ?assertEqual(ok, recycle(?MODULE)),

    spawn(fun() ->
        ?assertEqual(ok, new(?MODULE)),
        receive
            {?MSG_TAG, {recycled_integer, Int6}} -> Pid ! {?MSG_TAG, Int6}
        end,
        timer:sleep(1)
    end),
    spawn(fun() ->
        ?assertEqual(ok, new(?MODULE)),
        receive
            {?MSG_TAG, {recycled_integer, Int7}} -> Pid ! {?MSG_TAG, Int7}
        end,
        timer:sleep(1)
    end),
    spawn(fun() ->
        ?assertEqual(ok, new(?MODULE)),
        receive
            {?MSG_TAG, {recycled_integer, Int8}} -> Pid ! {?MSG_TAG, Int8}
        end,
        timer:sleep(1)
    end),
    receive
        {?MSG_TAG, IL1} -> IL1
    end,
    receive
        {?MSG_TAG, IL2} -> IL2
    end,
    receive
        {?MSG_TAG, IL3} -> IL3
    end,
    ?assertEqual([1, 2, 3], lists:sort([IL1, IL2, IL3])),

    ?assertEqual(ok, gen_server:stop(?MODULE)).

-endif.
