-module(temporal_sdk_telemetry).

% elp:ignore W0012 W0040
-moduledoc """
WIP Telemetry module.
""".

-export([
    setup/1,
    execute/2,
    execute/3,
    execute/4,
    spawn_execute/3,
    spawn_execute/4
]).
-export([
    do_execute/4
]).

-type exception() :: {
    Class :: error | exit | throw,
    Reason :: term(),
    Stacktrace :: erlang:raise_stacktrace() | erlang:stacktrace() | ExceptionDetails :: map()
}.
-export_type([exception/0]).

-define(EVENT_NAME_PREFIX, temporal_sdk).

-define(DEFAULT_EXECUTE_TIMEOUT, 10_000).

-spec setup(NodeOpts :: temporal_sdk_node:opts()) -> ok.
setup(#{telemetry_logs := TelemetryLogs}) ->
    temporal_sdk_telemetry_logs:setup(TelemetryLogs),
    % temporal_sdk_telemetry_traces:setup(),
    ok.

-spec execute(
    EventName :: telemetry:event_name(),
    Metadata :: telemetry:event_metadata()
) -> integer().
execute(EventName, Metadata) ->
    SystemTime = erlang:system_time(),
    spawn_execute(EventName, Metadata, #{system_time => SystemTime}),
    SystemTime.

-spec execute(
    EventName :: telemetry:event_name(),
    Metadata :: telemetry:event_metadata(),
    Measurement_Or_StartTime :: map() | integer()
) -> ok.
execute(EventName, Metadata, StartTime) when is_integer(StartTime) ->
    Duration = erlang:system_time() - StartTime,
    spawn_execute(EventName, Metadata, #{duration => Duration});
execute(EventName, Metadata, Measurement) when is_map(Measurement) ->
    spawn_execute(EventName, Metadata, Measurement).

-spec execute(
    EventName :: telemetry:event_name(),
    Metadata :: telemetry:event_metadata(),
    StartTime :: integer(),
    Exception :: exception()
) -> ok.
execute(EventName, Metadata, StartTime, {Class, Reason, Stacktrace}) when is_integer(StartTime) ->
    execute(
        EventName,
        Metadata#{class => Class, reason => do_reason(Class, Reason), stacktrace => Stacktrace},
        StartTime
    ).

do_reason(Class, {Class, Err}) -> Err;
do_reason(Class, {Class, Err1, Err2}) -> {Err1, Err2};
do_reason(_Class, Err) -> Err.

-spec spawn_execute(
    EventName :: telemetry:event_name(),
    Metadata :: telemetry:event_metadata(),
    Measurements :: telemetry:event_measurements() | telemetry:event_value()
) -> ok.
spawn_execute(EventName, Metadata, Measurements) ->
    spawn_execute(EventName, Metadata, Measurements, ?DEFAULT_EXECUTE_TIMEOUT).

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

%% -------------------------------------------------------------------------------------------------
%% private

-doc false.
do_execute(EventName, Metadata, Measurements, OtelCtx) ->
    otel_ctx:attach(OtelCtx),
    telemetry:execute(EventName, Measurements, Metadata).
