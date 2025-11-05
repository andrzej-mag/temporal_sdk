-module(temporal_sdk_utils_proc_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-import(temporal_sdk_utils_proc, [
    exit_after/3
]).

exit_after_test() ->
    Pids = [spawn(fun() -> timer:sleep(I) end) || I <- lists:seq(1, 50)],
    ?assertEqual([true], lists:sort(lists:uniq([is_process_alive(P) || P <- Pids]))),
    exit_after(30, Pids, {terminate, "reason"}),
    timer:sleep(10),
    ?assertEqual([false, true], lists:sort(lists:uniq([is_process_alive(P) || P <- Pids]))),
    timer:sleep(10),
    ?assertEqual([false, true], lists:sort(lists:uniq([is_process_alive(P) || P <- Pids]))),
    timer:sleep(20),
    ?assertEqual([false], lists:sort(lists:uniq([is_process_alive(P) || P <- Pids]))).

-endif.
