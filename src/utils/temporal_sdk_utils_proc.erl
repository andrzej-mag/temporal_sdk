-module(temporal_sdk_utils_proc).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    exit_after/2,
    exit_after/3
]).

-spec exit_after(Time :: non_neg_integer(), Target :: pid() | [pid()]) -> ok.
exit_after(Time, Target) ->
    exit_after(Time, Target, {shutdown, timeout}).

-spec exit_after(Time :: non_neg_integer(), Target :: pid() | [pid()], Reason :: term()) -> ok.
exit_after(Time, Target, Reason) when is_list(Target) ->
    spawn(fun() ->
        RefPidList = [
            begin
                Ref = monitor(process, Pid),
                {Ref, Pid}
            end
         || Pid <- Target
        ],
        do_exit_after(Time, RefPidList, Reason)
    end),
    ok;
exit_after(Time, Target, Reason) when is_pid(Target) ->
    exit_after(Time, [Target], Reason).

do_exit_after(Time, RefPidList, Reason) ->
    T1 = erlang:monotonic_time(millisecond),
    receive
        {'DOWN', Ref, process, Pid, _Reason} ->
            T2 = erlang:monotonic_time(millisecond),
            do_exit_after(Time - T2 + T1, lists:delete({Ref, Pid}, RefPidList), Reason)
    after Time ->
        lists:foreach(fun({_Ref, Pid}) when is_pid(Pid) -> exit(Pid, Reason) end, RefPidList)
    end.
