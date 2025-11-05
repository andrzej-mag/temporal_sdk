-module(temporal_sdk_utils_time).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    convert_to_msec/2,
    msec_to_protobuf/1,
    nanos_to_protobuf/1,
    protobuf_to_msec/1,
    protobuf_to_nanos/1,
    system_time_protobuf/0
]).

-include("proto.hrl").

-type time_unit() :: millisecond | second | minute | hour | day.
-export_type([time_unit/0]).

-spec convert_to_msec(Time :: number(), Unit :: time_unit()) -> TimeMsec :: integer().
convert_to_msec(Time, millisecond) when is_integer(Time) -> Time;
convert_to_msec(Time, second) when is_number(Time) -> round(1000 * Time);
convert_to_msec(Time, minute) when is_number(Time) -> round(60 * 1000 * Time);
convert_to_msec(Time, hour) when is_number(Time) -> round(60 * 60 * 1000 * Time);
convert_to_msec(Time, day) when is_number(Time) -> round(24 * 60 * 60 * 1000 * Time).

-spec msec_to_protobuf(TimeMsec :: integer()) -> ?TEMPORAL_SPEC:'google.protobuf.Duration'().
msec_to_protobuf(TimeMsec) when is_integer(TimeMsec), TimeMsec < 1_000, TimeMsec >= 0 ->
    #{seconds => 0, nanos => TimeMsec * 1_000_000};
msec_to_protobuf(TimeMsec) when is_integer(TimeMsec), TimeMsec >= 0 ->
    Seconds = floor(TimeMsec / 1_000),
    Nanos = (TimeMsec - Seconds * 1_000) * 1_000_000,
    #{seconds => Seconds, nanos => Nanos}.

-spec nanos_to_protobuf(TimeNanos :: non_neg_integer()) ->
    ?TEMPORAL_SPEC:'google.protobuf.Duration'().
nanos_to_protobuf(TimeNanos) when is_integer(TimeNanos), TimeNanos >= 0 ->
    Seconds = floor(TimeNanos / 1_000_000_000),
    Nanos = TimeNanos - Seconds * 1_000_000_000,
    #{seconds => Seconds, nanos => Nanos}.

-spec protobuf_to_msec(?TEMPORAL_SPEC:'google.protobuf.Duration'()) -> non_neg_integer().
protobuf_to_msec(#{seconds := Seconds, nanos := Nanos}) ->
    Seconds * 1000 + round(Nanos / 1_000_000);
protobuf_to_msec(#{seconds := Seconds}) ->
    Seconds * 1000;
protobuf_to_msec(#{nanos := Nanos}) ->
    round(Nanos / 1_000_000).

-spec protobuf_to_nanos(?TEMPORAL_SPEC:'google.protobuf.Duration'()) -> non_neg_integer().
protobuf_to_nanos(#{seconds := Seconds, nanos := Nanos}) ->
    Seconds * 1_000_000_000 + Nanos;
protobuf_to_nanos(#{seconds := Seconds}) ->
    Seconds * 1_000_000_000;
protobuf_to_nanos(#{nanos := Nanos}) ->
    Nanos.

-spec system_time_protobuf() -> ?TEMPORAL_SPEC:'google.protobuf.Duration'().
system_time_protobuf() -> nanos_to_protobuf(erlang:system_time(nanosecond)).
