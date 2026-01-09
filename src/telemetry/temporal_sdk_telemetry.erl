-module(temporal_sdk_telemetry).

% elp:ignore W0012 W0040 E1599
-moduledoc {file, "../../docs/telemetry/-module.md"}.

-export([
    events/0,
    events_by_prefix/1,
    events_by_suffix/1,
    handle_log/4
]).
-export([
    setup/1
]).
-export([
    execute/2,
    execute/3,
    execute/4,
    spawn_execute/3,
    spawn_execute/4
]).
-export([
    do_execute/4
]).

-include_lib("kernel/include/logger.hrl").

-doc """
Erlang exception.
""".
-type exception() :: {
    Class :: error | exit | throw,
    Reason :: term(),
    Stacktrace :: erlang:raise_stacktrace() | erlang:stacktrace() | ExceptionDetails :: map()
}.
-export_type([exception/0]).

-doc """
Telemetry events handlers list used in the SDK node configuration.

List of tuples.
First tuple element is a list of telemetry events or a zero arity function returing such list.
Second tuple element is a handler function which will be used to handle the events list defined as
the first element.
Example:
```erlang
[
    {
        [
            [temporal_sdk, workflow, task, start],
            [temporal_sdk, activity, task, start]
        ],
        fun my_app:handle_event/4
    },
    {
        fun my_app:telemetry_events_list/0,
        fun temporal_sdk_telemetry:handle_log/4
    }
]
```
""".
-type events_handlers() ::
    [
        {
            [telemetry:event_name()] | fun(() -> [telemetry:event_name()]),
            telemetry:handler_function()
        }
    ].
-export_type([events_handlers/0]).

-define(EVENT_NAME_PREFIX, temporal_sdk).

-define(DEFAULT_EXECUTE_TIMEOUT, 10_000).

-doc {file, "../../docs/telemetry/events-0.md"}.
-spec events() -> [telemetry:event_name()].
events() ->
    [
        %% temporal_sdk_node
        [temporal_sdk, node, init],
        [temporal_sdk, node, start],
        [temporal_sdk, node, stats],
        %% temporal_sdk_cluster
        [temporal_sdk, cluster, init],
        [temporal_sdk, cluster, start],
        [temporal_sdk, cluster, exception],
        [temporal_sdk, cluster, stats],
        %% temporal_sdk_worker
        [temporal_sdk, worker, init],
        [temporal_sdk, worker, start],
        [temporal_sdk, worker, stop],
        [temporal_sdk, worker, exception],
        [temporal_sdk, worker, stats],
        %% temporal_sdk_activity
        [temporal_sdk, activity, executor, start],
        [temporal_sdk, activity, executor, stop],
        [temporal_sdk, activity, executor, exception],
        [temporal_sdk, activity, task, start],
        [temporal_sdk, activity, task, stop],
        [temporal_sdk, activity, task, exception],
        [temporal_sdk, activity, execution, start],
        [temporal_sdk, activity, execution, stop],
        [temporal_sdk, activity, execution, exception],
        %% temporal_sdk_nexus
        [temporal_sdk, nexus, executor, start],
        [temporal_sdk, nexus, executor, stop],
        [temporal_sdk, nexus, executor, exception],
        [temporal_sdk, nexus, task, start],
        [temporal_sdk, nexus, task, stop],
        [temporal_sdk, nexus, task, exception],
        [temporal_sdk, nexus, execution, start],
        [temporal_sdk, nexus, execution, stop],
        [temporal_sdk, nexus, execution, exception],
        %% temporal_sdk_workflow
        [temporal_sdk, workflow, executor, start],
        [temporal_sdk, workflow, executor, stop],
        [temporal_sdk, workflow, executor, exception],
        [temporal_sdk, workflow, task, start],
        [temporal_sdk, workflow, task, stop],
        [temporal_sdk, workflow, task, exception],
        [temporal_sdk, workflow, execution, start],
        [temporal_sdk, workflow, execution, stop],
        [temporal_sdk, workflow, execution, exception],
        %% temporal_sdk_client
        [temporal_sdk, client, start],
        [temporal_sdk, client, stop],
        [temporal_sdk, client, exception],
        %% temporal_sdk_grpc
        [temporal_sdk, grpc, start],
        [temporal_sdk, grpc, stop],
        [temporal_sdk, grpc, exception],
        %% temporal_sdk_poller
        [temporal_sdk, poller, poll, start],
        [temporal_sdk, poller, poll, stop],
        [temporal_sdk, poller, poll, exception],
        [temporal_sdk, poller, execute, start],
        [temporal_sdk, poller, execute, stop],
        [temporal_sdk, poller, execute, exception],
        [temporal_sdk, poller, wait, start],
        [temporal_sdk, poller, wait, stop]
    ].

-doc {file, "../../docs/telemetry/events_by_prefix-1.md"}.
-spec events_by_prefix(PrefixFilter :: telemetry:event_name()) -> [telemetry:event_name()].
events_by_prefix(PrefixFilter) -> do_events_pf(PrefixFilter, []).

do_events_pf([PF | TPrefixFilter], Acc) when is_atom(PF) ->
    do_events_pf([[PF] | TPrefixFilter], Acc);
do_events_pf([PF | TPrefixFilter], Acc) when is_list(PF) ->
    do_events_pf(TPrefixFilter, Acc ++ lists:filter(fun(E) -> lists:prefix(PF, E) end, events()));
do_events_pf([], Acc) ->
    Acc.

-doc {file, "../../docs/telemetry/events_by_suffix-1.md"}.
-spec events_by_suffix(SuffixFilter :: telemetry:event_name()) -> [telemetry:event_name()].
events_by_suffix(SuffixFilter) -> do_events_sf(SuffixFilter, []).

do_events_sf([SF | TSuffixFilter], Acc) when is_atom(SF) ->
    do_events_sf([[SF] | TSuffixFilter], Acc);
do_events_sf([SF | TSuffixFilter], Acc) when is_list(SF) ->
    do_events_sf(TSuffixFilter, Acc ++ lists:filter(fun(E) -> lists:suffix(SF, E) end, events()));
do_events_sf([], Acc) ->
    Acc.

-doc {file, "../../docs/telemetry/handle_log-4.md"}.
-spec handle_log(
    Event :: [telemetry:event_name()],
    Measurements :: telemetry:event_measurements(),
    Metadata :: telemetry:event_metadata(),
    HandlerConfig :: telemetry:handler_config()
) -> any().
handle_log(Event, Measurements, Metadata, []) ->
    LogLevel =
        case lists:member(exception, Event) of
            true -> error;
            false -> notice
        end,
    M =
        case Measurements of
            #{duration := D} ->
                Metadata#{duration => erlang:convert_time_unit(D, native, millisecond)};
            #{} ->
                Metadata
        end,
    ?LOG(LogLevel, M#{telemetry_event => Event}).

-doc false.
-spec setup(NodeConfig :: map()) -> ok.
setup(#{telemetry_events_handlers := TEH}) when is_list(TEH) ->
    do_setup(TEH, 1);
setup(#{telemetry_events_handlers := false}) ->
    ok.

do_setup([{EventsFun, HandlerFun} | TTEH], HandlerId) when
    is_function(EventsFun), is_function(HandlerFun)
->
    do_setup([{EventsFun(), HandlerFun} | TTEH], HandlerId);
do_setup([{EventsList, HandlerFun} | TTEH], HandlerId) when
    is_list(EventsList), is_function(HandlerFun)
->
    HId = {?MODULE, HandlerId},
    case telemetry:attach_many(HId, EventsList, HandlerFun, []) of
        ok ->
            ok;
        Err ->
            temporal_sdk_utils_logger:log_error(
                Err,
                ?MODULE,
                ?FUNCTION_NAME,
                "Error attaching telemetry handler to the event.",
                #{handler_id => HId, events => EventsList, handler_function => HandlerFun}
            )
    end,
    do_setup(TTEH, HandlerId + 1);
do_setup([], _HandlerId) ->
    ok.

-doc false.
-spec execute(
    EventName :: telemetry:event_name(),
    Metadata :: telemetry:event_metadata()
) -> integer().
execute(EventName, Metadata) ->
    SystemTime = erlang:system_time(),
    spawn_execute(EventName, Metadata, #{system_time => SystemTime}),
    SystemTime.

-doc false.
-spec execute(
    EventName :: telemetry:event_name(),
    Metadata :: telemetry:event_metadata(),
    MeasurementsOrStartTime :: map() | integer()
) -> ok.
execute(EventName, Metadata, StartTime) when is_integer(StartTime) ->
    Duration = erlang:system_time() - StartTime,
    spawn_execute(EventName, Metadata, #{duration => Duration});
execute(EventName, Metadata, Measurements) when is_map(Measurements) ->
    spawn_execute(EventName, Metadata, Measurements).

-doc false.
-spec execute(
    EventName :: telemetry:event_name(),
    Metadata :: telemetry:event_metadata(),
    StartTime :: integer(),
    MeasurementsOrException :: map() | exception()
) -> ok.
execute(EventName, Metadata, StartTime, Measurements) when
    is_integer(StartTime), is_map(Measurements)
->
    Duration = erlang:system_time() - StartTime,
    spawn_execute(EventName, Metadata, Measurements#{duration => Duration});
execute(EventName, Metadata, StartTime, {Class, Reason, Stacktrace}) when is_integer(StartTime) ->
    execute(
        EventName,
        Metadata#{class => Class, reason => do_reason(Class, Reason), stacktrace => Stacktrace},
        StartTime
    ).

do_reason(Class, {Class, Err}) -> Err;
do_reason(Class, {Class, Err1, Err2}) -> {Err1, Err2};
do_reason(_Class, Err) -> Err.

-doc false.
-spec spawn_execute(
    EventName :: telemetry:event_name(),
    Metadata :: telemetry:event_metadata(),
    Measurements :: telemetry:event_measurements() | telemetry:event_value()
) -> ok.
spawn_execute(EventName, Metadata, Measurements) ->
    spawn_execute(EventName, Metadata, Measurements, ?DEFAULT_EXECUTE_TIMEOUT).

-doc false.
-spec spawn_execute(
    EventName :: telemetry:event_name(),
    Metadata :: telemetry:event_metadata(),
    Measurements :: telemetry:event_measurements() | telemetry:event_value(),
    Timeout :: non_neg_integer()
) -> ok.
spawn_execute(EventName, Metadata, Measurements, Timeout) ->
    TEventName = [?EVENT_NAME_PREFIX | EventName],
    Pid = spawn(?MODULE, do_execute, [TEventName, Metadata, Measurements, otel_ctx:get_current()]),
    temporal_sdk_utils_proc:exit_after(Timeout, Pid).

-doc false.
do_execute(EventName, Metadata, Measurements, OtelCtx) ->
    otel_ctx:attach(OtelCtx),
    telemetry:execute(EventName, Measurements, Metadata).
