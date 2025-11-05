-behaviour(temporal_sdk_workflow).

-include("sdk.hrl").

%% Temporal commands
-import(temporal_sdk_workflow, [
    start_activity/2,
    start_activity/3,
    cancel_activity/1,
    cancel_activity/2,

    record_marker/1,
    record_marker/2,

    start_timer/1,
    start_timer/2,
    cancel_timer/1,
    cancel_timer/2,

    start_child_workflow/2,
    start_child_workflow/3,

    start_nexus/4,
    start_nexus/5,
    % cancel_nexus

    modify_workflow_properties/1,
    modify_workflow_properties/2,
    % upsert_workflow_search_attributes

    % cancel_external_workflow
    % signal_external_workflow

    complete_workflow_execution/1,
    cancel_workflow_execution/1,
    fail_workflow_execution/1,
    continue_as_new_workflow/2,
    continue_as_new_workflow/3
]).

%% External Temporal commands
-import(temporal_sdk_workflow, [
    admit_signal/1,
    admit_signal/2,
    respond_query/2
    % respond_update
]).

%% Custom Temporal record marker commands
-import(temporal_sdk_workflow, [
    record_uuid4/0,
    record_uuid4/1,
    record_system_time/0,
    record_system_time/1,
    record_system_time/2,
    record_rand_uniform/0,
    record_rand_uniform/1,
    record_rand_uniform/2,
    record_env/1,
    record_env/2
]).

%% SDK await commands
-import(temporal_sdk_workflow, [
    await/1,
    await/2,
    await_one/1,
    await_one/2,
    await_all/1,
    await_all/2,

    await_info/1,
    await_info/3,

    is_awaited/1,
    is_awaited_one/1,
    is_awaited_all/1,

    wait/1,
    wait/2,
    wait_one/1,
    wait_one/2,
    wait_all/1,
    wait_all/2,

    wait_info/1,
    wait_info/3
]).

%% SDK commands
-import(temporal_sdk_workflow, [
    start_execution/1,
    start_execution/2,
    start_execution/3,
    start_execution/4,

    set_info/1,
    set_info/2,

    workflow_info/0,
    get_workflow_result/0,
    set_workflow_result/1,
    stop/0,
    stop/1,
    await_open_before_close/1,

    select_index/1,
    select_index/2,
    select_history/1,
    select_history/2
]).
