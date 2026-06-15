-behaviour(temporal_sdk_activity).

-include("sdk.hrl").

-import(temporal_sdk_activity, [
    await_data/1,
    await_data/2,

    complete/1,
    cancel/1,
    fail/1,
    fail/3,

    heartbeat/0,
    heartbeat/1,

    last_heartbeat/0,
    cancel_requested/0,
    activity_paused/0,
    elapsed_time/0,
    elapsed_time/1,
    remaining_time/0,
    remaining_time/1,

    get_data/0,
    set_data/1
]).
