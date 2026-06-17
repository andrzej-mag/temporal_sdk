Temporal activity task module.

## OpenTelemetry

Activity execution inherits its OpenTelemetry trace from the parent workflow. Traces propagate across
Temporal tasks via task headers, using the W3C Trace Context standard through `m:otel_propagator_text_map`.

Once activity execution starts, a new OpenTelemetry `"RunActivity"` span is created using the parent
workflow's context. OpenTelemetry context is attached to the activity execution process, enabling
standard OpenTelemetry commands, such as adding user-defined spans, attributes, events, etc.

`"RunActivity"` span is created after activity task is polled and execution processing starts using
worker node local time.
`"RunActivity"` span includes an OpenTelemetry event `"StartActivityTask"` created at the activity task
(server) `started_time`.

[SDK Samples](https://github.com/andrzej-mag/temporal_sdk_samples)
[Otel Sample](https://hexdocs.pm/temporal_sdk_samples/otel_sample.html) demonstrates how to extract
baggage from the inherited trace context, add span attributes, and start a new span.
