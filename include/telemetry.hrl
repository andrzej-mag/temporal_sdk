%% Module including this file must define ev_origin/0 and ev_metadata/1 functions.

-define(EVST, begin
    {current_stacktrace, CurrentStacktrace} = process_info(self(), current_stacktrace),
    CurrentStacktrace
end).

-define(EV(StateData, Event),
    temporal_sdk_telemetry:execute(
        [ev_origin() | Event], ev_metadata(StateData)
    )
).

-define(EV(StateData, Event, StartTime),
    temporal_sdk_telemetry:execute(
        [ev_origin() | Event], ev_metadata(StateData), StartTime
    )
).

-define(EV(StateData, Event, StartTime, Exception),
    temporal_sdk_telemetry:execute(
        [ev_origin() | Event], ev_metadata(StateData), StartTime, Exception
    )
).
