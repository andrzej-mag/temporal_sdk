Telemetry event handler translating telemetry events to logger events.

Handler emits logger events from telemetry events.
If a telemetry event contains `exception` in its event name, the logger event is logged with `error`
log level. All other events are logged with `notice` log level.
Telemetry `metadata` is logged as log event metadata.
Telemetry `measurements` are discarded, except for the `duration` key.
If a telemetry event's measurements contain the `duration` key, it is added to the log metadata.

Function is expected to be used in `t:events_handlers/0` tuple within the SDK node configuration.
