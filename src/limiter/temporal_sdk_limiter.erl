-module(temporal_sdk_limiter).
-behaviour(gen_server).

% elp:ignore W0012 W0040
-moduledoc """
Rate limiter module.
""".

-export([
    setup/2,
    build_checks/2,
    build_counters/2,
    is_allowed/1,
    inc/1,
    dec/1,
    get_concurrency/1
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

-type level() :: os | node | cluster | worker.
-export_type([level/0]).

-type os_limitable() :: cpu1 | cpu5 | cpu15 | mem | {disk, Id :: string()}.
-export_type([os_limitable/0]).

-type temporal_limitable() ::
    activity_regular | activity_session | activity_eager | activity_direct | workflow | nexus.
-export_type([temporal_limitable/0]).

-type limitable() :: os_limitable() | temporal_limitable().
-export_type([limitable/0]).

-type time_window() ::
    {Length :: pos_integer(), Unit :: temporal_sdk:time_unit()}
    | LengthMsec :: erlang:timeout().

-export_type([time_window/0]).

-type time_windows() :: #{limitable() => time_window()}.
-export_type([time_windows/0]).

-type limit() ::
    {MaxConcurrency :: pos_integer(), MaxFrequency :: pos_integer()}
    | OsMaxLimit :: pos_integer().
-export_type([limit/0]).

-type limits() :: #{limitable() => limit()}.
-export_type([limits/0]).

-type levels_limits() :: #{level() => limits()}.
-export_type([levels_limits/0]).

-type user_levels_limits() :: [{level(), limits()}].
-export_type([user_levels_limits/0]).

-type counter() :: #{limitable() => counters:counters_ref()}.
-export_type([counter/0]).

-type counters() :: #{level() => counter()}.
-export_type([counters/0]).

-type check() :: {{level(), limitable()}, counters:counters_ref(), [pos_integer()]}.
-export_type([check/0]).

-type checks() :: [check()].
-export_type([checks/0]).

-type check_ret() :: true | {level(), limitable()}.
-export_type([check_ret/0]).

-type stats() :: #{limitable() => -1 | pos_integer()}.
-export_type([stats/0]).

%% -------------------------------------------------------------------------------------------------
%% internal API

-doc false.
-spec setup(LimiterId :: tuple(), TimeWindows :: time_windows()) ->
    {Counter :: counter(), LimiterChiSpec :: supervisor:child_spec()}.
setup(LimiterId, TimeWindows) ->
    Fn = fun
        (L, {Time, Unit}, {LAcc, TWAcc}) when is_integer(Time) ->
            T = temporal_sdk_utils_time:convert_to_msec(Time, Unit),
            C = counters:new(2, [write_concurrency]),
            {LAcc#{L => C}, TWAcc#{C => T}};
        (L, T, {LAcc, TWAcc}) when is_integer(T) ->
            C = counters:new(2, [write_concurrency]),
            {LAcc#{L => C}, TWAcc#{C => T}}
    end,
    {UserCounters, CountersWindows} = maps:fold(Fn, {#{}, #{}}, TimeWindows),
    ChiSpec = #{id => LimiterId, start => {?MODULE, start_link, [LimiterId, CountersWindows]}},
    {UserCounters, ChiSpec}.

-doc false.
-spec build_checks(LevelsLimits :: levels_limits(), Counters :: counters()) ->
    {ok, checks()}
    | {invalid_opts, Reason :: map()}.
build_checks(LevelsLimits, Counters) ->
    maybe
        {ok, Checks} ?= do_build_checks([os, node, cluster, worker], LevelsLimits, Counters, []),
        ok ?= is_checks_valid(Checks),
        {ok, Checks}
    end.

is_checks_valid([{{Layer1, Limitable1}, _CounterRef1, Limits1} | TChecks]) ->
    Fn = fun
        ({{_Layer2, Limitable2}, _CounterRef2, Limits2}) when Limitable2 =:= Limitable1 ->
            limits_gt(Limits1, Limits2);
        (_) ->
            false
    end,
    case lists:filter(Fn, TChecks) of
        [] ->
            is_checks_valid(TChecks);
        Err ->
            {invalid_opts, #{
                reason =>
                    "Violated rate limiter levels limits condition: node >= cluster >= worker.",
                invalid_limits =>
                    lists:map(
                        fun({{Layer, Limitable}, _, Limits}) -> {Layer, Limitable, Limits} end, Err
                    ),
                violated_limit => {Layer1, Limitable1, Limits1}
            }}
    end;
is_checks_valid([]) ->
    ok.

limits_gt(L1, L2) when is_integer(L1), is_integer(L2) -> limits_gt([L1], [L2]);
limits_gt(Limits1, Limits2) when is_tuple(Limits1), is_tuple(Limits2) ->
    limits_gt(tuple_to_list(Limits1), tuple_to_list(Limits2));
limits_gt([L1 | _TL1], [L2 | _TL2]) when L1 > L2 -> true;
limits_gt([_L1 | TL1], [_L2 | TL2]) ->
    limits_gt(TL1, TL2);
limits_gt([], []) ->
    false.

do_build_checks([Layer | TLayer], Limits, Counters, Acc) ->
    case {Limits, Counters} of
        {#{Layer := Li}, #{Layer := Co}} ->
            case do_build_layer_checks(maps:to_list(Li), Co, Layer, []) of
                {ok, C} -> do_build_checks(TLayer, Limits, Counters, C ++ Acc);
                Err -> Err
            end;
        {#{Layer := _}, #{}} ->
            {invalid_opts, #{
                reason => "Missing rate limiter layer configuration.",
                missing_layer => Layer,
                invalid_config => Counters
            }};
        {#{}, #{Layer := _}} ->
            {invalid_opts, #{
                reason => "Missing rate limiter layer configuration.",
                missing_layer => Layer,
                invalid_config => Limits
            }};
        {#{}, #{}} ->
            {invalid_opts, #{
                reason => "Missing rate limiter layer configuration.",
                missing_layer => Layer,
                invalid_limits => Limits,
                invalid_counters => Counters
            }}
    end;
do_build_checks([], _Limits, _Counters, Acc) ->
    {ok, Acc}.

do_build_layer_checks([{Limitable, Limit} | TLimits], Counters, Layer, Acc) ->
    case Counters of
        #{Limitable := C} ->
            Lim =
                case Limit of
                    L when is_tuple(L) -> tuple_to_list(L);
                    L when is_integer(L) -> [L]
                end,
            do_build_layer_checks(TLimits, Counters, Layer, [{{Layer, Limitable}, C, Lim} | Acc]);
        #{} ->
            {invalid_opts, #{
                reason => "Invalid rate limiter limitable configuration",
                invalid_limitable => Limitable,
                available_counters => Counters,
                layer => Layer
            }}
    end;
do_build_layer_checks([], _Counters, _Layer, Acc) ->
    {ok, lists:sort(Acc)}.

-doc false.
-spec build_counters(Limitable :: limitable(), Counters :: counters()) ->
    {ok, [counters:counters_ref()]}
    | {invalid_opts, Reason :: map()}.
build_counters(Limitable, Counters) ->
    do_build_counters(maps:to_list(maps:without([os], Counters)), Limitable, []).

do_build_counters([{Layer, Counters} | TCounters], Limitable, Acc) ->
    case Counters of
        #{Limitable := C} ->
            do_build_counters(TCounters, Limitable, [C | Acc]);
        #{} ->
            {invalid_opts, #{
                reason => "Missing or invalid rate limiter limitable configuration.",
                limitable => Limitable,
                available_counters => Counters,
                layer => Layer
            }}
    end;
do_build_counters([], _Limitable, Acc) ->
    {ok, Acc}.

-doc false.
-spec is_allowed(Checks :: checks()) -> check_ret().
is_allowed([{LayerLimitable, CounterRef, Limits} | TChecks]) ->
    case do_is_allowed(Limits, CounterRef, 1) of
        true -> is_allowed(TChecks);
        false -> LayerLimitable
    end;
is_allowed([]) ->
    true.

do_is_allowed([Limit | Limits], CounterRef, Ix) ->
    case Limit > counters:get(CounterRef, Ix) of
        true -> do_is_allowed(Limits, CounterRef, Ix + 1);
        false -> false
    end;
do_is_allowed([], _CounterRef, _Ix) ->
    true.

-doc false.
-spec inc(Counters :: [counters:counters_ref()]) -> ok.
inc(Counters) ->
    lists:foreach(
        fun(C) ->
            counters:add(C, 1, 1),
            counters:add(C, 2, 1)
        end,
        Counters
    ).

-doc false.
-spec dec(Counters :: [counters:counters_ref()]) -> ok.
dec(Counters) ->
    lists:foreach(fun(C) -> counters:sub(C, 1, 1) end, Counters).

-doc false.
-spec reset_frequency(CounterRef :: counters:counters_ref()) -> ok.
reset_frequency(CounterRef) -> counters:put(CounterRef, 2, 0).

-doc false.
-spec get_concurrency(Counter :: counter()) -> stats().
get_concurrency(Counter) -> maps:map(fun(_L, C) -> counters:get(C, 1) end, Counter).

%% -------------------------------------------------------------------------------------------------
%% gen_server

-doc false.
-spec start_link(
    LimiterId :: tuple(), CountersWindows :: [{counters:counters_ref(), pos_integer()}]
) -> gen_server:start_ret().
start_link(LimiterId, CountersWindows) ->
    gen_server:start_link(?MODULE, [LimiterId, CountersWindows], []).

-doc false.
init([LimiterId, CountersWindows]) ->
    ProcLabel = temporal_sdk_utils_path:string_path([?MODULE | tuple_to_list(LimiterId)]),
    proc_lib:set_label(ProcLabel),
    {ok, [], {continue, CountersWindows}}.

-doc false.
handle_continue(CountersWindows, []) ->
    maps:foreach(
        fun(CounterRef, Interval) when is_integer(Interval) ->
            erlang:send_after(jitter(Interval), self(), {reset, CounterRef})
        end,
        CountersWindows
    ),
    {noreply, CountersWindows}.

-doc false.
handle_info({reset, CounterRef}, State) ->
    reset_frequency(CounterRef),
    case State of
        #{CounterRef := Interval} ->
            erlang:send_after(jitter(Interval), self(), {reset, CounterRef}),
            {noreply, State};
        #{} ->
            {stop, "Malformed state.", State}
    end;
handle_info(_Info, State) ->
    {stop, invalid_request, State}.

-doc false.
handle_call(_Request, _From, State) ->
    {stop, invalid_request, State}.

-doc false.
handle_cast(_Request, State) ->
    {stop, invalid_request, State}.

jitter(Interval) -> Interval + rand:uniform(10).
