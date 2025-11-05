-module(temporal_sdk_limiter_os).
-behaviour(gen_server).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    setup/0,
    get_stats/1
]).
-export([
    start_link/2
]).
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_continue/2,
    handle_info/2
]).

-spec setup() ->
    {
        Counter :: temporal_sdk_limiter:counter(),
        LimiterChiSpec :: supervisor:child_spec(),
        DiskMounts :: [string()]
    }.
setup() ->
    C1 =
        case erlang:whereis(cpu_sup) of
            undefined ->
                #{};
            _PidCpu ->
                #{
                    cpu1 => counters:new(1, []),
                    cpu5 => counters:new(1, []),
                    cpu15 => counters:new(1, [])
                }
        end,
    Counters =
        case erlang:whereis(memsup) of
            undefined -> C1;
            _PidMem -> C1#{mem => counters:new(1, [])}
        end,
    {UserCounters, DiskCounters, DiskMounts} =
        case erlang:whereis(disksup) of
            undefined ->
                {Counters, [], []};
            _PidDisk ->
                DCZip = lists:map(
                    fun({Id, _Total, _Capacity}) ->
                        C = counters:new(1, []),
                        {{{disk, Id}, C}, {Id, C}, Id}
                    end,
                    disksup:get_disk_data()
                ),
                {UDCounters, DCounters, DMounts} = lists:unzip3(DCZip),
                {maps:merge(Counters, proplists:to_map(UDCounters)), DCounters, DMounts}
        end,
    ChiSpec = #{id => {?MODULE}, start => {?MODULE, start_link, [Counters, DiskCounters]}},
    {UserCounters, ChiSpec, DiskMounts}.

-spec get_stats(Counter :: temporal_sdk_limiter:counter()) -> temporal_sdk_limiter:stats().
get_stats(Counter) -> maps:map(fun(_L, C) -> counters:get(C, 1) end, Counter).

%% -------------------------------------------------------------------------------------------------
%% gen_server

start_link(Counters, DiskCounters) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [Counters, DiskCounters], []).

init([Counters, DiskCounters]) ->
    {ok, [], {continue, [Counters, DiskCounters]}}.

handle_continue([Counters, DiskCounters], []) ->
    maps:foreach(
        fun(L, _C) -> erlang:send_after(get_check_interval(init), self(), {update, L}) end, Counters
    ),
    case DiskCounters of
        [] -> ok;
        [_ | _] -> erlang:send_after(get_check_interval(init), self(), {update, disk})
    end,
    {noreply, {Counters, DiskCounters}}.

handle_info({update, Limitable}, State) ->
    case put(Limitable, get_data(Limitable), State) of
        ok ->
            erlang:send_after(get_check_interval(Limitable), self(), {update, Limitable}),
            {noreply, State};
        Err ->
            {stop, Err, State}
    end;
handle_info(_Info, State) ->
    {stop, invalid_request, State}.

handle_call(_Request, _From, State) ->
    {stop, invalid_request, State}.

handle_cast(_Request, State) ->
    {stop, invalid_request, State}.

get_check_interval(Limitable) ->
    do_get_check_interval(Limitable) + rand:uniform(10).

do_get_check_interval(init) -> 0;
do_get_check_interval(cpu1) -> 1_000;
do_get_check_interval(cpu5) -> 5_000;
do_get_check_interval(cpu15) -> 15_000;
do_get_check_interval(mem) -> memsup:get_check_interval();
do_get_check_interval(disk) -> disksup:get_check_interval().

get_data(cpu1) ->
    case cpu_sup:avg1() of
        0 -> -1;
        V -> V
    end;
get_data(cpu5) ->
    case cpu_sup:avg5() of
        0 -> -1;
        V -> V
    end;
get_data(cpu15) ->
    case cpu_sup:avg15() of
        0 -> -1;
        V -> V
    end;
get_data(mem) ->
    case memsup:get_memory_data() of
        {0, 0, _} -> -1;
        {Total, Allocated, _Worst} -> round(Allocated / Total * 100)
    end;
get_data(disk) ->
    disksup:get_disk_data().

put(disk, Data, {Counters, [{Id, C} | TDiskCounters]}) ->
    case lists:keyfind(Id, 1, Data) of
        {Id, _, Capacity} when is_integer(Capacity), Capacity >= 0 -> counters:put(C, 1, Capacity);
        _ -> counters:put(C, 1, -1)
    end,
    put(disk, Data, {Counters, TDiskCounters});
put(disk, _Data, {_Counters, []}) ->
    ok;
put(Limitable, Value, {Counters, _DiskCounters}) ->
    case Counters of
        #{Limitable := C} -> counters:put(C, 1, Value);
        _ -> {error, "Malformed state."}
    end.
