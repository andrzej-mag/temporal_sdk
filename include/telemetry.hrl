%% Module including this file must define ev_origin/0 and ev_metadata/1 functions.

-define(EVST, begin
    {current_stacktrace, CurrentStacktrace} = process_info(self(), current_stacktrace),
    CurrentStacktrace
end).

-define(EV(StateData, Event),
    case ev_metadata(StateData) of
        #{disable_telemetry := true} -> erlang:system_time();
        #{} -> temporal_sdk_telemetry:execute([ev_origin() | Event], ev_metadata(StateData))
    end
).

-define(EV(StateData, Event, MeasurementsOrStartTime),
    case ev_metadata(StateData) of
        #{disable_telemetry := true} ->
            ok;
        #{} ->
            temporal_sdk_telemetry:execute(
                [ev_origin() | Event], ev_metadata(StateData), MeasurementsOrStartTime
            )
    end
).

-define(EV(StateData, Event, StartTime, MeasurementsOrException),
    case ev_metadata(StateData) of
        #{disable_telemetry := true} ->
            ok;
        #{} ->
            temporal_sdk_telemetry:execute(
                [ev_origin() | Event], ev_metadata(StateData), StartTime, MeasurementsOrException
            )
    end
).
