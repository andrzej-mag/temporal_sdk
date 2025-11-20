-module(temporal_sdk_workflow).

% elp:ignore W0012 W0040
-moduledoc {file, "../../docs/temporal_sdk/operator/-module.md"}.

%% Temporal commands
-export([
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
-export([
    admit_signal/1,
    admit_signal/2,
    respond_query/2
    % respond_update
]).

%% Custom Temporal record marker commands
-export([
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
-export([
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
-export([
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

-import(temporal_sdk_executor, [
    cast/1,
    call_id/1,
    cast_id/1
]).

-include("proto.hrl").

-define(DEFAULT_ACTIVITY_START_TO_CLOSE_TIMEOUT_HEARTBEAT_MULTIPLICATION, 1000).
-define(DEFAULT_ACTIVITY_START_TO_CLOSE_TIMEOUT_DIRECT_EXECUTION,
    temporal_sdk_utils_time:msec_to_protobuf(temporal_sdk_utils_time:convert_to_msec(1, minute))
).
-define(DEFAULT_ACTIVITY_START_TO_CLOSE_TIMEOUT,
    temporal_sdk_utils_time:msec_to_protobuf(temporal_sdk_utils_time:convert_to_msec(10, minute))
).

-define(API_CTX, temporal_sdk_executor:get_api_context()).
-define(API_CTX_ACTIVITY, temporal_sdk_executor:get_api_context_activity()).
-define(EXECUTION_ID, temporal_sdk_executor:get_execution_id()).
-define(EXECUTION_IDX, temporal_sdk_executor:get_execution_idx()).
-define(HISTORY_TABLE, temporal_sdk_executor:get_history_table()).
-define(INDEX_TABLE, temporal_sdk_executor:get_index_table()).
-define(OTEL_CONTEXT, temporal_sdk_executor:get_otel_context()).
-define(AWAIT_COUNTER, temporal_sdk_executor:get_await_counter()).
-define(COMMANDS, temporal_sdk_executor:get_commands()).

%% -------------------------------------------------------------------------------------------------
%% SDK functions types

-doc #{group => "SDK functions types"}.
-type workflow_info() ::
    #{
        event_id := pos_integer(),
        is_replaying := boolean(),
        open_executions_count := pos_integer(),
        open_tasks_count := non_neg_integer(),
        attempt := pos_integer(),
        suggest_continue_as_new := boolean(),
        history_size_bytes := non_neg_integer(),
        otp_messages_count := #{
            received => non_neg_integer(),
            recorded => non_neg_integer(),
            ignored => non_neg_integer()
        }
    }.
-export_type([workflow_info/0]).

-doc #{group => "SDK functions types"}.
-type start_execution_opts() :: [
    {execution_id, execution_id()}
    | {awaitable_id, awaitable_id()}
    | {awaitable_event, [cmd | close]}
    | {wait, boolean()}
    | wait
].
-export_type([start_execution_opts/0]).

%% -------------------------------------------------------------------------------------------------
%% Temporal commands opts

-doc #{group => "Temporal commands opts"}.
-type awaitable_id() ::
    #{
        id => unicode:chardata() | atom(),
        prefix => boolean() | unicode:chardata() | atom(),
        postfix => boolean() | unicode:chardata() | atom()
    }
    | unicode:chardata()
    | atom().
-export_type([awaitable_id/0]).

-doc #{group => "Temporal commands opts"}.
-type start_activity_opts() :: [
    {activity_id, unicode:chardata() | atom()}
    | {task_queue, unicode:chardata()}
    | {header, temporal_sdk:term_to_mapstring_payload()}
    %% temporal.api.common.v1.Payloads input = 6;
    | {schedule_to_close_timeout, temporal_sdk:time()}
    | {schedule_to_start_timeout, temporal_sdk:time()}
    | {start_to_close_timeout, temporal_sdk:time()}
    | {heartbeat_timeout, temporal_sdk:time()}
    | {retry_policy, temporal_sdk:retry_policy()}
    | {eager_execution, boolean()}
    | eager_execution
    | {use_workflow_build_id, boolean()}
    | use_workflow_build_id
    | {priority, ?TEMPORAL_SPEC:'temporal.api.common.v1.Priority'()}
    %% SDK
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'()}
    | {awaitable_id, awaitable_id()}
    | {awaitable_event, [cmd | cancel_request | result | schedule | start | close]}
    | {wait, boolean()}
    | wait
    | {direct_execution, boolean()}
    | direct_execution
    | {direct_result, boolean()}
    | direct_result
    | {session_execution, boolean()}
    | session_execution
    | {node_execution_fun, function()}
].
-export_type([start_activity_opts/0]).

-doc #{group => "Temporal commands opts"}.
-type record_marker_mutable_opts() ::
    #{mutations_limit := pos_integer(), fail_on_limit := boolean()} | boolean().
-export_type([record_marker_mutable_opts/0]).

-doc #{group => "Temporal commands opts"}.
-type marker_value_codec() ::
    none
    | list
    | term
    | {
        Encoder ::
            none
            | fun((term()) -> temporal_sdk:term_to_payloads())
            | {Module :: module(), Function :: atom()},
        Decoder ::
            none
            | fun((temporal_sdk:term_from_payloads()) -> term())
            | {Module :: module(), Function :: atom()}
    }.
-export_type([marker_value_codec/0]).

-doc #{group => "Temporal commands opts"}.
-type record_marker_opts() :: [
    {marker_name, atom() | unicode:chardata()}
    | {header, temporal_sdk:term_to_mapstring_payload()}
    %% SDK
    | {awaitable_id, awaitable_id()}
    | {awaitable_event, [cmd | value | close]}
    | {wait, boolean()}
    | wait
    | {type, temporal_sdk:convertable()}
    | {details, temporal_sdk:term_to_mapstring_payloads()}
    | {mutable, record_marker_mutable_opts()}
    | mutable
    | {value_codec, marker_value_codec()}
].
-export_type([record_marker_opts/0]).

-doc #{group => "Temporal commands opts"}.
-type record_marker_value_fun() ::
    fun(() -> temporal_sdk:term_to_payloads() | term())
    | {module(), atom()}
    | {module(), atom(), term()}.

-doc #{group => "Temporal commands opts"}.
-type start_timer_opts() :: [
    {timer_id, atom() | unicode:chardata()}
    %% SDK
    | {awaitable_id, awaitable_id()}
    | {awaitable_event, [cmd | cancel_request | close]}
    | {wait, boolean()}
    | wait
].
-export_type([start_timer_opts/0]).

-doc #{group => "Temporal commands opts"}.
-type start_child_workflow_opts() :: [
    {namespace, unicode:chardata()}
    | {workflow_id, unicode:chardata()}
    %% temporal.api.common.v1.WorkflowType workflow_type = 3;
    %% temporal.api.taskqueue.v1.TaskQueue task_queue = 4;
    | {input, temporal_sdk:term_to_payloads()}
    | {workflow_execution_timeout, temporal_sdk:time()}
    | {workflow_run_timeout, temporal_sdk:time()}
    | {workflow_task_timeout, temporal_sdk:time()}
    | {parent_close_policy, ?TEMPORAL_SPEC:'temporal.api.enums.v1.ParentClosePolicy'()}
    | {workflow_id_reuse_policy, ?TEMPORAL_SPEC:'temporal.api.enums.v1.WorkflowIdReusePolicy'()}
    | {retry_policy, temporal_sdk:retry_policy()}
    | {cron_schedule, unicode:chardata()}
    | {header, temporal_sdk:term_to_mapstring_payload()}
    | {memo, temporal_sdk:term_to_mapstring_payload()}
    | {search_attributes, temporal_sdk:term_to_mapstring_payload()}
    | {priority, ?TEMPORAL_SPEC:'temporal.api.common.v1.Priority'()}
    %% SDK
    | {raw_request,
        ?TEMPORAL_SPEC:'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'()}
    | {awaitable_id, awaitable_id()}
    | {awaitable_event, [cmd | initiate | start | close]}
    | {wait, boolean()}
    | wait
].
-export_type([start_child_workflow_opts/0]).

-doc #{group => "Temporal commands opts"}.
-type start_nexus_opts() :: [
    %% string endpoint = 1;
    %% string service = 2;
    %% string operation = 3;
    %% temporal.api.common.v1.Payload input = 4;
    {schedule_to_close_timeout, temporal_sdk:time()}
    %% map<string, string> nexus_header = 6;
    %% SDK options
    | {awaitable_id, awaitable_id()}
    | {awaitable_event, [cmd | cancel_request | close]}
    | {wait, boolean()}
    | wait
].

-doc #{group => "Temporal commands opts"}.
-type continue_as_new_workflow_opts() :: [
    %% temporal.api.common.v1.WorkflowType workflow_type = 1;
    %% temporal.api.taskqueue.v1.TaskQueue task_queue = 2;
    {input, temporal_sdk:term_to_payloads()}
    | {workflow_run_timeout, temporal_sdk:time()}
    | {workflow_task_timeout, temporal_sdk:time()}
    | {backoff_start_interval, temporal_sdk:time()}
    | {retry_policy, temporal_sdk:retry_policy()}
    | {header, temporal_sdk:term_to_mapstring_payload()}
    | {memo, temporal_sdk:term_to_mapstring_payload()}
    | {search_attributes, temporal_sdk:term_to_mapstring_payload()}
].
-export_type([continue_as_new_workflow_opts/0]).

-doc #{group => "Temporal external commands opts"}.
-type admit_signal_opts() :: [
    {details, term()}
    %% SDK options
    | {awaitable_event, [request | admit | close]}
    | {wait, boolean()}
    | wait
].
-export_type([admit_signal_opts/0]).

-doc #{group => "Temporal external commands opts"}.
-type respond_query_opts() :: [
    {result_type, ?TEMPORAL_SPEC:'temporal.api.enums.v1.QueryResultType'()}
    | {answer, temporal_sdk:term_to_payloads()}
    | {error_message, unicode:chardata()}
    | {failure,
        temporal_sdk:application_failure()
        | temporal_sdk:user_application_failure()}
    %% SDK options
    | {awaitable_event, [request | response | close]}
    | {wait, boolean()}
    | wait
].
-export_type([respond_query_opts/0]).

%% -------------------------------------------------------------------------------------------------
%% Awaitables types

%% history

-doc #{group => "Awaitables types"}.
-type event_id() :: pos_integer().
-export_type([event_id/0]).

-doc #{group => "Awaitables types"}.
-type history_event() :: {
    EventId :: event_id(),
    EventType :: ?TEMPORAL_SPEC:'temporal.api.enums.v1.EventType'(),
    EventAttributes :: map(),
    EventData :: map()
}.
-export_type([history_event/0]).
-doc #{group => "Awaitables types"}.
-type history_event_pattern() :: {
    '_' | EventId :: event_id(),
    '_' | EventType :: ?TEMPORAL_SPEC:'temporal.api.enums.v1.EventType'(),
    '_' | EventAttributes :: map(),
    '_' | EventData :: map()
}.
-export_type([history_event_pattern/0]).
-doc #{group => "Awaitables types"}.
-type history_event_event_pattern() :: {event, history_event_pattern()}.
-doc #{group => "Awaitables types"}.
-type history_event_table_pattern() :: {
    ets_matchvar() | EventId :: event_id(),
    ets_matchvar() | EventType :: ?TEMPORAL_SPEC:'temporal.api.enums.v1.EventType'(),
    ets_matchvar() | EventAttributes :: map(),
    ets_matchvar() | EventData :: map()
}.
-export_type([history_event_table_pattern/0]).
-doc #{group => "Awaitables types"}.
-type history_event_table_pattern_match_spec() ::
    [{EtsMatchHead :: history_event_table_pattern(), EtsMatchGuard :: [_], EtsMatchResult :: [_]}].
-doc #{group => "Awaitables types"}.
-type event_data() :: #{
    event_id := event_id(),
    type := ?TEMPORAL_SPEC:'temporal.api.enums.v1.EventType'(),
    attributes := map(),
    data := map()
}.
-export_type([event_data/0]).

%% awaitable

-doc #{group => "Awaitables types"}.
-type awaitable() ::
    %% SDK
    info()
    | execution()
    | suggest_continue_as_new()
    %% Temporal
    | activity()
    | marker()
    | timer()
    | child_workflow()
    | nexus()
    | workflow_properties()
    | complete_workflow_execution()
    | cancel_workflow_execution()
    | fail_workflow_execution()
    | continue_as_new_workflow()
    %% external requests
    | cancel_request()
    | signal()
    | query()
    %% Temporal history event
    | history_event().
-export_type([awaitable/0]).

-doc #{group => "Awaitables types"}.
-type awaitable_data() ::
    %% SDK
    % info_data()
    execution_data()
    | suggest_continue_as_new_data()
    %% Temporal
    | activity_data()
    | marker_data()
    | timer_data()
    | child_workflow_data()
    | nexus_data()
    | workflow_properties_data()
    | complete_workflow_execution_data()
    | cancel_workflow_execution_data()
    | fail_workflow_execution_data()
    | continue_as_new_workflow_data()
    %% external requests
    | cancel_request_data()
    | signal_data()
    | query_data()
    %% Temporal history event
    | event_data().
-export_type([awaitable_data/0]).

-doc #{group => "Awaitables types"}.
-type awaitable_state() ::
    cmd
    | scheduled
    | started
    | canceled
    | completed
    | failed
    | initiated
    | initiate_failed
    | fired
    | modified
    | recorded
    | continued
    | requested
    | signaled
    | responded
    | suggested
    | admitted.
-export_type([awaitable_state/0]).

%% awaitables

-doc #{group => "Awaitables types"}.
-type info() :: {info, InfoId :: term()}.
-export_type([info/0]).
-doc #{group => "Awaitables types"}.
-type info_pattern() :: {info, '_' | InfoId :: term()}.
-doc #{group => "Awaitables types"}.
-type info_index_key() :: {info, InfoId :: term()}.
-doc #{group => "Awaitables types"}.
-type info_index_key_pattern() :: {info, ets_matchvar() | InfoId :: term()}.
-doc #{group => "Awaitables types"}.
-type info_data() :: InfoData :: term() | awaitable().
-export_type([info_data/0]).

%% doc:
%% `undefined` execution_id is reserved for the OTP marker messages and for the
%% complete_workflow_execution command automatically issued after all parallel executions are
%% completed.
-doc #{group => "Awaitables types"}.
-type execution_id() :: term().
-export_type([execution_id/0]).
-doc #{group => "Awaitables types"}.
-type execution_event() :: execution_cmd | execution_start | execution.
-doc #{group => "Awaitables types"}.
-type execution() :: {execution_event(), ExecutionId :: execution_id()}.
-export_type([execution/0]).
-doc #{group => "Awaitables types"}.
-type execution_pattern() :: {execution_event(), '_' | ExecutionId :: execution_id()}.
-doc #{group => "Awaitables types"}.
-type execution_index_key() :: {execution, ExecutionId :: execution_id()}.
-doc #{group => "Awaitables types"}.
-type execution_index_key_pattern() :: {execution, ets_matchvar() | ExecutionId :: execution_id()}.

-doc #{group => "Awaitables types"}.
-type execution_result() :: term().
-export_type([execution_result/0]).
-doc #{group => "Awaitables types"}.
-type execution_data() ::
    #{
        state := cmd,
        mfa := {Module :: module(), Function :: atom(), Args :: term()}
    }
    | #{
        state := started,
        mfa := {Module :: module(), Function :: atom(), Args :: term()}
    }
    | #{
        state := completed,
        mfa := {Module :: module(), Function :: atom(), Args :: term()},
        result => execution_result()
    }.
-export_type([execution_data/0]).

-doc #{group => "Awaitables types"}.
-type suggest_continue_as_new() :: {suggest_continue_as_new}.
-export_type([suggest_continue_as_new/0]).
-doc #{group => "Awaitables types"}.
-type suggest_continue_as_new_pattern() :: {suggest_continue_as_new}.
-doc #{group => "Awaitables types"}.
-type suggest_continue_as_new_index_key() :: {suggest_continue_as_new}.
-doc #{group => "Awaitables types"}.
-type suggest_continue_as_new_index_key_pattern() :: {suggest_continue_as_new}.
-doc #{group => "Awaitables types"}.
-type suggest_continue_as_new_data() :: #{state := suggested, event_id := event_id()}.
-export_type([suggest_continue_as_new_data/0]).

-doc #{group => "Awaitables types"}.
-type activity_event() ::
    activity_cmd
    | activity_cancel_request
    | activity_result
    | activity_schedule
    | activity_start
    %% closed states: completed, canceled, failed, timedout
    | activity.
-doc #{group => "Awaitables types"}.
-type activity() :: {activity_event(), ActivityId :: unicode:chardata()}.
-export_type([activity/0]).
-doc #{group => "Awaitables types"}.
-type activity_pattern() :: {activity_event(), '_' | ActivityId :: unicode:chardata() | atom()}.
-doc #{group => "Awaitables types"}.
-type activity_index_key() :: {activity, ActivityId :: unicode:chardata()}.
-export_type([activity_index_key/0]).
-doc #{group => "Awaitables types"}.
-type activity_index_key_pattern() :: {activity, ets_matchvar() | ActivityId :: unicode:chardata()}.
-doc #{group => "Awaitables types"}.
-type activity_data() ::
    #{
        state := cmd,
        execution_id := execution_id(),
        event_id := event_id(),
        task_queue := unicode:chardata(),
        activity_type := unicode:chardata() | atom(),
        session_execution := boolean(),
        eager_execution := boolean(),
        direct_execution := boolean(),
        direct_result := boolean(),
        result => temporal_sdk:term_to_payloads(),
        last_failure => temporal_sdk_telemetry:exception(),
        heartbeat_timeout => pos_integer(),
        cancel_requested => true,
        history => [map()]
    }
    | #{
        state := scheduled,
        execution_id := execution_id(),
        event_id := event_id(),
        task_queue := unicode:chardata(),
        activity_type := unicode:chardata() | atom(),
        session_execution := boolean(),
        eager_execution := boolean(),
        direct_execution := boolean(),
        direct_result := boolean(),
        result => temporal_sdk:term_to_payloads(),
        last_failure => temporal_sdk_telemetry:exception(),
        heartbeat_timeout => pos_integer(),
        cancel_requested => true,
        history => [map()]
    }
    | #{
        state := started,
        execution_id := execution_id(),
        event_id := event_id(),
        task_queue := unicode:chardata(),
        activity_type := unicode:chardata() | atom(),
        session_execution := boolean(),
        eager_execution := boolean(),
        direct_execution := boolean(),
        direct_result := boolean(),
        result => temporal_sdk:term_to_payloads(),
        last_failure =>
            temporal_sdk_telemetry:exception() | temporal_sdk:failure_from_temporal(),
        heartbeat_timeout => pos_integer(),
        cancel_requested => true,
        scheduled_event_id := event_id(),
        history => [map()]
    }
    | #{
        state := completed,
        execution_id := execution_id(),
        event_id := event_id(),
        task_queue := unicode:chardata(),
        activity_type := unicode:chardata() | atom(),
        session_execution := boolean(),
        eager_execution := boolean(),
        direct_execution := boolean(),
        direct_result := boolean(),
        result => temporal_sdk:term_from_payloads(),
        last_failure =>
            temporal_sdk_telemetry:exception() | temporal_sdk:failure_from_temporal(),
        heartbeat_timeout => pos_integer(),
        cancel_requested => true,
        scheduled_event_id := event_id(),
        started_event_id := event_id(),
        attempt := pos_integer(),
        history => [map()]
    }
    | #{
        state := canceled,
        execution_id := execution_id(),
        event_id := event_id(),
        task_queue := unicode:chardata(),
        activity_type := unicode:chardata() | atom(),
        session_execution := boolean(),
        eager_execution := boolean(),
        direct_execution := boolean(),
        direct_result := boolean(),
        result => temporal_sdk:term_to_payloads(),
        last_failure =>
            temporal_sdk_telemetry:exception() | temporal_sdk:failure_from_temporal(),
        heartbeat_timeout => pos_integer(),
        cancel_requested := true,
        scheduled_event_id := event_id(),
        started_event_id := event_id(),
        attempt := pos_integer(),
        details := temporal_sdk:term_from_payloads(),
        history => [map()]
    }
    | #{
        state := failed,
        execution_id := execution_id(),
        event_id := event_id(),
        task_queue := unicode:chardata(),
        activity_type := unicode:chardata() | atom(),
        session_execution := boolean(),
        eager_execution := boolean(),
        direct_execution := boolean(),
        direct_result := boolean(),
        result => temporal_sdk:term_to_payloads(),
        last_failure =>
            temporal_sdk_telemetry:exception() | temporal_sdk:failure_from_temporal(),
        heartbeat_timeout => pos_integer(),
        cancel_requested => true,
        scheduled_event_id := event_id(),
        started_event_id := event_id(),
        failure => temporal_sdk:failure_from_temporal(),
        retry_state := ?TEMPORAL_SPEC:'temporal.api.enums.v1.RetryState'(),
        history => [map()]
    }
    | #{
        state := timedout,
        execution_id := execution_id(),
        event_id := event_id(),
        task_queue := unicode:chardata(),
        activity_type := unicode:chardata() | atom(),
        session_execution := boolean(),
        eager_execution := boolean(),
        direct_execution := boolean(),
        direct_result := boolean(),
        result => temporal_sdk:term_to_payloads(),
        last_failure =>
            temporal_sdk_telemetry:exception() | temporal_sdk:failure_from_temporal(),
        heartbeat_timeout => pos_integer(),
        cancel_requested => true,
        scheduled_event_id := event_id(),
        started_event_id := event_id(),
        failure => temporal_sdk:failure_from_temporal(),
        retry_state := ?TEMPORAL_SPEC:'temporal.api.enums.v1.RetryState'(),
        history => [map()]
    }.
-export_type([activity_data/0]).

-doc #{group => "Awaitables types"}.
-type marker_event() ::
    marker_cmd
    | marker_value
    %% closed state: recorded
    | marker.
-doc #{group => "Awaitables types"}.
-type marker() ::
    {
        marker_event(),
        MarkerType :: unicode:chardata() | atom(),
        MarkerName :: unicode:chardata() | atom()
    }.
-export_type([marker/0]).
-doc #{group => "Awaitables types"}.
-type marker_pattern() ::
    {
        marker_event(),
        '_' | MarkerType :: unicode:chardata() | atom(),
        '_' | MarkerName :: unicode:chardata() | atom()
    }.
-doc #{group => "Awaitables types"}.
-type marker_index_key() ::
    {marker, MarkerType :: unicode:chardata(), MarkerName :: unicode:chardata()}.
-export_type([marker_index_key/0]).
-doc #{group => "Awaitables types"}.
-type marker_index_key_pattern() ::
    {marker, ets_matchvar() | MarkerType :: unicode:chardata() | atom(),
        ets_matchvar() | MarkerName :: unicode:chardata() | atom()}.
-doc #{group => "Awaitables types"}.
-type marker_data() ::
    #{
        state := cmd,
        execution_id := execution_id(),
        event_id := event_id(),
        mutable => true,
        mutations_count => non_neg_integer(),
        details := temporal_sdk:term_to_mapstring_payload(),
        value => temporal_sdk:term_to_payloads() | term(),
        history => [map()]
    }
    | #{
        state := recorded,
        execution_id := execution_id(),
        event_id := event_id(),
        mutable => true,
        mutations_count => non_neg_integer(),
        details := temporal_sdk:term_from_mapstring_payload(),
        value := temporal_sdk:term_from_payloads() | term(),
        history => [map()]
    }
    %% OTP message marker
    | #{
        state := recorded,
        execution_id := undefined,
        event_id := event_id(),
        value := temporal_sdk:term_from_payloads(),
        history => [map()]
    }.
-export_type([marker_data/0]).

-doc #{group => "Awaitables types"}.
-type timer_event() ::
    timer_cmd
    | timer_cancel_request
    | timer_start
    %% closed states: fired, canceled
    | timer.
-doc #{group => "Awaitables types"}.
-type timer() :: {timer_event(), TimerId :: unicode:chardata() | atom()}.
-export_type([timer/0]).
-doc #{group => "Awaitables types"}.
-type timer_pattern() :: {timer_event(), '_' | TimerId :: unicode:chardata() | atom()}.
-doc #{group => "Awaitables types"}.
-type timer_index_key() :: {timer, TimerId :: unicode:chardata()}.
-export_type([timer_index_key/0]).
-doc #{group => "Awaitables types"}.
-type timer_index_key_pattern() :: {timer, ets_matchvar() | TimerId :: unicode:chardata()}.
-doc #{group => "Awaitables types"}.
-type timer_data() ::
    #{
        state := cmd,
        execution_id := execution_id(),
        event_id := event_id(),
        cancel_requested => true,
        history => [map()]
    }
    | #{
        state := started,
        execution_id := execution_id(),
        event_id := event_id(),
        cancel_requested => true,
        history => [map()]
    }
    | #{
        state := fired,
        execution_id := execution_id(),
        event_id := event_id(),
        started_event_id := event_id(),
        cancel_requested => true,
        history => [map()]
    }
    | #{
        state := canceled,
        execution_id := execution_id(),
        event_id := event_id(),
        started_event_id := event_id(),
        cancel_requested := true,
        history => [map()]
    }.
-export_type([timer_data/0]).

-doc #{group => "Awaitables types"}.
-type child_workflow_event() :: [
    child_workflow_cmd
    | child_workflow_initiate
    | child_workflow_start
    %% closed states: initiate_failed, completed, failed, canceled, timedout, terminated
    | child_workflow
].
-doc #{group => "Awaitables types"}.
-type child_workflow() :: {child_workflow_event(), ChildWorkflowId :: unicode:chardata()}.
-export_type([child_workflow/0]).
-doc #{group => "Awaitables types"}.
-type child_workflow_pattern() :: {
    child_workflow_event(), '_' | ChildWorkflowId :: unicode:chardata()
}.
-doc #{group => "Awaitables types"}.
-type child_workflow_index_key() :: {child_workflow, ChildWorkflowId :: unicode:chardata()}.
-doc #{group => "Awaitables types"}.
-type child_workflow_index_key_pattern() ::
    {child_workflow, ets_matchvar() | ChildWorkflowId :: unicode:chardata()}.
-doc #{group => "Awaitables types"}.
-type child_workflow_data() ::
    #{
        state := cmd,
        execution_id := execution_id(),
        event_id := event_id(),
        namespace := unicode:chardata(),
        task_queue := unicode:chardata(),
        workflow_type := unicode:chardata() | atom(),
        history => [map()]
    }
    | #{
        state := initiated,
        execution_id := execution_id(),
        event_id := event_id(),
        namespace := unicode:chardata(),
        task_queue := unicode:chardata(),
        workflow_type := unicode:chardata() | atom(),
        history => [map()]
    }
    | #{
        state := initiate_failed,
        execution_id := execution_id(),
        event_id := event_id(),
        namespace := unicode:chardata(),
        task_queue := unicode:chardata(),
        workflow_type := unicode:chardata() | atom(),
        history => [map()],
        initiated_event_id := event_id(),
        cause := ?TEMPORAL_SPEC:'temporal.api.enums.v1.StartChildWorkflowExecutionFailedCause'()
    }
    | #{
        state := started,
        execution_id := execution_id(),
        event_id := event_id(),
        namespace := unicode:chardata(),
        task_queue := unicode:chardata(),
        workflow_type := unicode:chardata() | atom(),
        history => [map()],
        initiated_event_id := event_id(),
        run_id := unicode:chardata()
    }
    | #{
        state := completed,
        execution_id := execution_id(),
        event_id := event_id(),
        namespace := unicode:chardata(),
        task_queue := unicode:chardata(),
        workflow_type := unicode:chardata() | atom(),
        history => [map()],
        initiated_event_id := event_id(),
        run_id := unicode:chardata(),
        started_event_id := event_id(),
        result := temporal_sdk:term_from_payloads()
    }
    | #{
        state := failed,
        execution_id := execution_id(),
        event_id := event_id(),
        namespace := unicode:chardata(),
        task_queue := unicode:chardata(),
        workflow_type := unicode:chardata() | atom(),
        history => [map()],
        initiated_event_id := event_id(),
        run_id := unicode:chardata(),
        started_event_id := event_id(),
        failure => temporal_sdk:failure_from_temporal()
    }
    | #{
        state := canceled,
        execution_id := execution_id(),
        event_id := event_id(),
        namespace := unicode:chardata(),
        task_queue := unicode:chardata(),
        workflow_type := unicode:chardata() | atom(),
        history => [map()],
        initiated_event_id := event_id(),
        run_id := unicode:chardata(),
        started_event_id := event_id(),
        details := temporal_sdk:term_from_payloads()
    }
    | #{
        state := timedout,
        execution_id := execution_id(),
        event_id := event_id(),
        namespace := unicode:chardata(),
        task_queue := unicode:chardata(),
        workflow_type := unicode:chardata() | atom(),
        history => [map()],
        initiated_event_id := event_id(),
        run_id := unicode:chardata(),
        started_event_id := event_id(),
        retry_state := ?TEMPORAL_SPEC:'temporal.api.enums.v1.RetryState'()
    }
    | #{
        state := terminated,
        execution_id := execution_id(),
        event_id := event_id(),
        namespace := unicode:chardata(),
        task_queue := unicode:chardata(),
        workflow_type := unicode:chardata() | atom(),
        history => [map()],
        initiated_event_id := event_id(),
        run_id := unicode:chardata(),
        started_event_id := event_id()
    }.
-export_type([child_workflow_data/0]).

-doc #{group => "Awaitables types"}.
-type nexus_event() ::
    nexus_cmd
    | nexus_cancel_request
    | nexus_schedule
    | nexus_start
    | nexus.
-doc #{group => "Awaitables types"}.
-type nexus() ::
    {
        nexus_event(),
        Endpoint :: unicode:chardata() | atom(),
        Service :: unicode:chardata() | atom(),
        Operation :: unicode:chardata() | atom()
    }.
-export_type([nexus/0]).
-doc #{group => "Awaitables types"}.
-type nexus_pattern() ::
    {
        nexus_event(),
        '_' | Endpoint :: unicode:chardata() | atom(),
        '_' | Service :: unicode:chardata() | atom(),
        '_' | Operation :: unicode:chardata() | atom()
    }.
-doc #{group => "Awaitables types"}.
-type nexus_index_key() ::
    {nexus, Endpoint :: unicode:chardata(), Service :: unicode:chardata(),
        Operation :: unicode:chardata()}.
-export_type([nexus_index_key/0]).
-doc #{group => "Awaitables types"}.
-type nexus_index_key_pattern() ::
    {
        nexus,
        ets_matchvar() | Endpoint :: unicode:chardata(),
        ets_matchvar() | Service :: unicode:chardata(),
        ets_matchvar() | Operation :: unicode:chardata()
    }.
-doc #{group => "Awaitables types"}.
-type nexus_data() ::
    #{
        state := cmd,
        execution_id := execution_id(),
        event_id := event_id(),
        input := temporal_sdk:term_to_payload(),
        cancel_requested => true,
        history => [map()]
    }
    | #{
        state := scheduled,
        execution_id := execution_id(),
        event_id := event_id(),
        input := temporal_sdk:term_from_payload(),
        cancel_requested => true,
        history => [map()]
    }
    | #{
        state := started,
        execution_id := execution_id(),
        event_id := event_id(),
        input := temporal_sdk:term_from_payload(),
        cancel_requested => true,
        history => [map()]
    }
    | #{
        state := completed,
        execution_id := execution_id(),
        event_id := event_id(),
        input := temporal_sdk:term_from_payload(),
        result => temporal_sdk:term_from_payload(),
        cancel_requested => true,
        history => [map()]
    }
    | #{
        state := canceled,
        execution_id := execution_id(),
        event_id := event_id(),
        input := temporal_sdk:term_from_payload(),
        failure => ?TEMPORAL_SPEC:'temporal.api.failure.v1.Failure'(),
        cancel_requested := true,
        history => [map()]
    }.
-export_type([nexus_data/0]).

-doc #{group => "Awaitables types"}.
-type workflow_properties_event() :: workflow_properties_cmd | workflow_properties.
-doc #{group => "Awaitables types"}.
-type workflow_properties() :: {workflow_properties_event()}.
-export_type([workflow_properties/0]).
-doc #{group => "Awaitables types"}.
-type workflow_properties_pattern() :: {workflow_properties_event()}.
-doc #{group => "Awaitables types"}.
-type workflow_properties_index_key() :: {workflow_properties}.
-export_type([workflow_properties_index_key/0]).
-doc #{group => "Awaitables types"}.
-type workflow_properties_index_key_pattern() :: {workflow_properties}.
-doc #{group => "Awaitables types"}.
-type workflow_properties_data() ::
    #{
        state := cmd,
        execution_id := execution_id(),
        event_id := event_id(),
        upserted_memo := temporal_sdk:term_to_mapstring_payload(),
        history => [map()]
    }
    | #{
        state := modified,
        execution_id := execution_id(),
        event_id := event_id(),
        upserted_memo := temporal_sdk:term_from_mapstring_payload(),
        history => [map()]
    }.
-export_type([workflow_properties_data/0]).

-doc #{group => "Awaitables types"}.
-type complete_workflow_execution() :: {complete_workflow_execution}.
-export_type([complete_workflow_execution/0]).
-doc #{group => "Awaitables types"}.
-type complete_workflow_execution_index_key() :: {complete_workflow_execution}.
-export_type([complete_workflow_execution_index_key/0]).
-doc #{group => "Awaitables types"}.
-type complete_workflow_execution_index_key_pattern() :: {complete_workflow_execution}.
-doc #{group => "Awaitables types"}.
-type complete_workflow_execution_data() ::
    #{
        state := cmd,
        execution_id := execution_id() | undefined,
        event_id => event_id(),
        result := temporal_sdk:term_to_payloads()
    }
    | #{
        state := completed,
        execution_id := execution_id() | undefined,
        event_id := event_id(),
        result := temporal_sdk:term_from_payloads()
    }.
-export_type([complete_workflow_execution_data/0]).

-doc #{group => "Awaitables types"}.
-type cancel_workflow_execution() :: {cancel_workflow_execution}.
-export_type([cancel_workflow_execution/0]).
-doc #{group => "Awaitables types"}.
-type cancel_workflow_execution_index_key() :: {cancel_workflow_execution}.
-export_type([cancel_workflow_execution_index_key/0]).
-doc #{group => "Awaitables types"}.
-type cancel_workflow_execution_index_key_pattern() :: {cancel_workflow_execution}.
-doc #{group => "Awaitables types"}.
-type cancel_workflow_execution_data() ::
    #{
        state := cmd,
        execution_id := execution_id(),
        details := temporal_sdk:term_to_payloads()
    }
    | #{
        state := canceled,
        execution_id := execution_id(),
        event_id := event_id(),
        details := temporal_sdk:term_from_payloads()
    }.
-export_type([cancel_workflow_execution_data/0]).

-doc #{group => "Awaitables types"}.
-type fail_workflow_execution() :: {fail_workflow_execution}.
-export_type([fail_workflow_execution/0]).
-doc #{group => "Awaitables types"}.
-type fail_workflow_execution_index_key() :: {fail_workflow_execution}.
-export_type([fail_workflow_execution_index_key/0]).
-doc #{group => "Awaitables types"}.
-type fail_workflow_execution_index_key_pattern() :: {fail_workflow_execution}.
-doc #{group => "Awaitables types"}.
-type fail_workflow_execution_data() ::
    #{
        state := cmd,
        execution_id := execution_id(),
        failure :=
            temporal_sdk:application_failure()
            | temporal_sdk:user_application_failure()
    }
    | #{
        state := failed,
        execution_id := execution_id(),
        event_id := event_id(),
        failure := temporal_sdk:failure_from_temporal()
    }.
-export_type([fail_workflow_execution_data/0]).

-doc #{group => "Awaitables types"}.
-type continue_as_new_workflow() :: {continue_as_new_workflow}.
-export_type([continue_as_new_workflow/0]).
-doc #{group => "Awaitables types"}.
-type continue_as_new_workflow_index_key() :: {continue_as_new_workflow}.
-export_type([continue_as_new_workflow_index_key/0]).
-doc #{group => "Awaitables types"}.
-type continue_as_new_workflow_index_key_pattern() :: {continue_as_new_workflow}.
-doc #{group => "Awaitables types"}.
-type continue_as_new_workflow_data() ::
    #{
        state := cmd,
        execution_id := execution_id(),
        task_queue := unicode:chardata(),
        workflow_type := unicode:chardata()
    }
    | #{
        state := continued,
        execution_id := execution_id(),
        event_id := event_id(),
        task_queue := unicode:chardata(),
        workflow_type := unicode:chardata()
    }.
-export_type([continue_as_new_workflow_data/0]).

%% external awaitables

-doc #{group => "Awaitables types"}.
-type cancel_request_event() :: cancel_request.
-doc #{group => "Awaitables types"}.
-type cancel_request() :: {cancel_request_event()}.
-export_type([cancel_request/0]).
-doc #{group => "Awaitables types"}.
-type cancel_request_pattern() :: {cancel_request_event()}.
-doc #{group => "Awaitables types"}.
-type cancel_request_index_key() :: {cancel_request}.
-export_type([cancel_request_index_key/0]).
-doc #{group => "Awaitables types"}.
-type cancel_request_index_key_pattern() :: {cancel_request}.
-doc #{group => "Awaitables types"}.
-type cancel_request_data() ::
    #{
        state := requested,
        event_id := event_id(),
        cause => unicode:chardata(),
        external_initiated_event_id => pos_integer(),
        external_workflow_execution => temporal_sdk:workflow_execution(),
        identity => unicode:chardata()
    }.
-export_type([cancel_request_data/0]).

-doc #{group => "Awaitables types"}.
-type signal_event() :: signal_request | signal_admit | signal.
-doc #{group => "Awaitables types"}.
-type signal() :: {signal_event(), SignalName :: unicode:chardata()}.
-export_type([signal/0]).
-doc #{group => "Awaitables types"}.
-type signal_pattern() :: {signal_event(), '_' | SignalName :: unicode:chardata()}.
-doc #{group => "Awaitables types"}.
-type signal_index_key() :: {signal, SignalName :: unicode:chardata()}.
-export_type([signal_index_key/0]).
-doc #{group => "Awaitables types"}.
-type signal_index_key_pattern() :: {signal, ets_matchvar() | SignalName :: unicode:chardata()}.
-doc #{group => "Awaitables types"}.
-type signal_data() ::
    #{
        state := requested,
        event_id := event_id(),
        input := temporal_sdk:term_from_payloads(),
        identity := unicode:chardata(),
        header := temporal_sdk:term_from_mapstring_payload(),
        external_workflow_execution => temporal_sdk:workflow_execution(),
        history => [map()]
    }
    | #{
        state := admitted,
        event_id := event_id(),
        input := temporal_sdk:term_from_payloads(),
        identity := unicode:chardata(),
        header := temporal_sdk:term_from_mapstring_payload(),
        external_workflow_execution => temporal_sdk:workflow_execution(),
        details => term(),
        history => [map()]
    }.
-export_type([signal_data/0]).

-doc #{group => "Awaitables types"}.
-type query_event() :: query_request | query_response | query.
-doc #{group => "Awaitables types"}.
-type query() :: {query_event(), QueryType :: unicode:chardata()}.
-export_type([query/0]).
-doc #{group => "Awaitables types"}.
-type query_pattern() :: {query_event(), '_' | QueryType :: unicode:chardata()}.
-doc #{group => "Awaitables types"}.
-type query_index_key() :: {query, QueryType :: unicode:chardata()}.
-export_type([query_index_key/0]).
-doc #{group => "Awaitables types"}.
-type query_index_key_pattern() :: {query, ets_matchvar() | QueryType :: unicode:chardata()}.
-doc #{group => "Awaitables types"}.
-type query_data() ::
    #{
        '_sdk_data' := term(),
        state := requested,
        query_args => temporal_sdk:term_from_payloads(),
        header => temporal_sdk:term_from_mapstring_payload(),
        history => [map()]
    }
    | #{
        state := responded,
        query_args => temporal_sdk:term_from_payloads(),
        header => temporal_sdk:term_from_mapstring_payload(),
        answer => temporal_sdk:term_to_payloads(),
        error_message => unicode:chardata(),
        failure =>
            temporal_sdk:application_failure()
            | temporal_sdk:user_application_failure(),
        history => [map()]
    }.
-export_type([query_data/0]).

%% -------------------------------------------------------------------------------------------------
%% Awaitables functions types

%% pattern

-doc #{group => "Awaitables functions types"}.
-type awaitable_pattern() ::
    awaitable_data()
    %% SDK
    | info_pattern()
    | execution_pattern()
    | suggest_continue_as_new_pattern()
    %% Temporal
    | activity_pattern()
    | marker_pattern()
    | timer_pattern()
    | child_workflow_pattern()
    | nexus_pattern()
    | workflow_properties_pattern()
    %% external
    | cancel_request_pattern()
    | signal_pattern()
    | query_pattern()
    %% Temporal history event
    | history_event_event_pattern().
-export_type([awaitable_pattern/0]).

-doc #{group => "Awaitables functions types"}.
-type await_pattern_all() ::
    {all, [awaitable_pattern() | await_pattern_one() | await_pattern_all()]}.
-doc #{group => "Awaitables functions types"}.
-type await_pattern_one() ::
    {one, [awaitable_pattern() | await_pattern_one() | await_pattern_all()]}.
-doc #{group => "Awaitables functions types"}.
-type await_pattern() :: awaitable_pattern() | await_pattern_all() | await_pattern_one().
-export_type([await_pattern/0]).

%% match

-doc #{group => "Awaitables functions types"}.
-type awaitable_match() :: awaitable_data() | info_data() | noevent.
-export_type([awaitable_match/0]).

-doc #{group => "Awaitables functions types"}.
-type await_match_all() :: {all, [awaitable_match() | await_match_one() | await_match_all()]}.
-doc #{group => "Awaitables functions types"}.
-type await_match_one() :: {one, [awaitable_match() | await_match_one() | await_match_all()]}.
-doc #{group => "Awaitables functions types"}.
-type await_match() :: awaitable_match() | await_match_all() | await_match_one().
-export_type([await_match/0]).

-doc #{group => "Awaitables functions types"}.
-type await_ret() ::
    {ok, await_match()} | {noevent, PartialMatch :: await_match()} | no_return().
-export_type([await_ret/0]).

-doc #{group => "Awaitables functions types"}.
-type await_ret_list() ::
    {ok, [await_match()]} | {noevent, [ProperOrPartialMatch :: await_match()]} | no_return().
-export_type([await_ret_list/0]).

%% index table

-doc false.
-type command() :: ?TEMPORAL_SPEC:'temporal.api.command.v1.Command'() | sdk_command | map().
-export_type([command/0]).

-doc false.
-type index_command() :: {awaitable_index(), command()}.
-export_type([index_command/0]).

-doc #{group => "SDK functions types"}.
-type awaitable_temporal_index() ::
    {activity_index_key(), activity_data()}
    | {marker_index_key(), marker_data()}
    | {timer_index_key(), timer_data()}
    | {child_workflow_index_key(), child_workflow_data()}
    | {nexus_index_key(), nexus_data()}
    | {workflow_properties_index_key(), workflow_properties_data()}
    | {complete_workflow_execution_index_key(), complete_workflow_execution_data()}
    | {cancel_workflow_execution_index_key(), cancel_workflow_execution_data()}
    | {fail_workflow_execution_index_key(), fail_workflow_execution_data()}
    | {continue_as_new_workflow_index_key(), continue_as_new_workflow_data()}
    %% external
    | {cancel_request_index_key(), cancel_request_data()}
    | {signal_index_key(), signal_data()}
    | {query_index_key(), query_data()}.
-export_type([awaitable_temporal_index/0]).

-doc #{group => "SDK functions types"}.
-type awaitable_index() ::
    awaitable_temporal_index()
    | {info_index_key(), info_data()}
    | {execution_index_key(), execution_data()}
    | {suggest_continue_as_new_index_key(), suggest_continue_as_new_data()}.
-export_type([awaitable_index/0]).

-doc false.
-type awaitable_index_key_pattern() ::
    %% SDK
    info_index_key_pattern()
    | execution_index_key_pattern()
    | suggest_continue_as_new_index_key_pattern()
    %% Temporal
    | activity_index_key_pattern()
    | marker_index_key_pattern()
    | timer_index_key_pattern()
    | child_workflow_index_key_pattern()
    | nexus_index_key_pattern()
    | workflow_properties_index_key_pattern()
    | complete_workflow_execution_index_key_pattern()
    | cancel_workflow_execution_index_key_pattern()
    | fail_workflow_execution_index_key_pattern()
    | continue_as_new_workflow_index_key_pattern()
    %% external
    | cancel_request_index_key_pattern()
    | signal_index_key_pattern()
    | query_index_key_pattern().
-export_type([awaitable_index_key_pattern/0]).

-doc #{group => "SDK functions types"}.
-type awaitable_index_pattern() ::
    %% SDK
    {info_index_key_pattern(), ets_matchvar() | term()}
    | {execution_index_key_pattern(), ets_matchvar() | map()}
    | {suggest_continue_as_new_index_key_pattern(), ets_matchvar() | map()}
    %% Temporal
    | {activity_index_key_pattern(), ets_matchvar() | map()}
    | {marker_index_key_pattern(), ets_matchvar() | map()}
    | {timer_index_key_pattern(), ets_matchvar() | map()}
    | {child_workflow_index_key_pattern(), ets_matchvar() | map()}
    | {nexus_index_key_pattern(), ets_matchvar() | map()}
    | {workflow_properties_index_key_pattern(), ets_matchvar() | map()}
    | {complete_workflow_execution_index_key_pattern(), ets_matchvar() | map()}
    | {cancel_workflow_execution_index_key_pattern(), ets_matchvar() | map()}
    | {fail_workflow_execution_index_key_pattern(), ets_matchvar() | map()}
    | {continue_as_new_workflow_index_key_pattern(), ets_matchvar() | map()}
    %% external
    | {cancel_request_index_key_pattern(), ets_matchvar() | map()}
    | {signal_index_key_pattern(), ets_matchvar() | map()}
    | {query_index_key_pattern(), ets_matchvar() | map()}.
-export_type([awaitable_index_pattern/0]).

-doc #{group => "SDK functions types"}.
-type awaitable_index_pattern_match_spec() ::
    [{EtsMatchHead :: awaitable_index_pattern(), EtsMatchGuard :: [_], EtsMatchResult :: [_]}].
-export_type([awaitable_index_pattern_match_spec/0]).

%% index table internal typespecs

-doc false.
-type awaitable_index_key() ::
    %% SDK
    info()
    | execution_index_key()
    | suggest_continue_as_new_index_key()
    %% Temporal
    | activity_index_key()
    | marker_index_key()
    | timer_index_key()
    | child_workflow_index_key()
    | nexus_index_key()
    | workflow_properties_index_key()
    | complete_workflow_execution_index_key()
    | cancel_workflow_execution_index_key()
    | fail_workflow_execution_index_key()
    | continue_as_new_workflow_index_key()
    %% external
    | cancel_request_index_key()
    | signal_index_key()
    | query_index_key().
-export_type([awaitable_index_key/0]).

-doc false.
-type awaitable_index_data() ::
    noevent | info_data() | awaitable_data().
-export_type([awaitable_index_data/0]).

%% ets typespecs

-doc #{group => "SDK functions types"}.
-type ets_matchvar() :: '_' | '$1' | '$2' | '$3' | '$4' | atom().

-doc #{group => "SDK functions types"}.
-type ets_continuation() ::
    '$end_of_table'
    | {ets:table(), integer(), integer(), ets:compiled_match_spec(), list(), integer()}
    | {ets:table(), _, _, integer(), ets:compiled_match_spec(), list(), integer(), integer()}.

%% -------------------------------------------------------------------------------------------------
%% Workflow behaviour

-doc #{group => "Workflow behaviour"}.
-type task() :: ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.PollWorkflowTaskQueueResponse'().
-export_type([task/0]).

-doc #{group => "Workflow behaviour"}.
-type context() ::
    #{
        cluster := temporal_sdk_cluster:cluster_name(),
        executor_pid := pid(),
        otel_ctx := otel_ctx:t(),
        execution_id := execution_id(),
        worker_opts := temporal_sdk_worker:opts(),
        history_table := ets:table(),
        index_table := ets:table(),
        workflow_info := context_workflow_info(),
        task := task(),
        %% from PollWorkflowTaskQueueResponse:
        attempt := pos_integer(),
        is_replaying := boolean()
    }.
-export_type([context/0]).

-doc #{group => "Workflow behaviour"}.
-type context_workflow_info() :: #{
    %% from PollWorkflowTaskQueueResponse:
    workflow_execution := ?TEMPORAL_SPEC:'temporal.api.common.v1.WorkflowExecution'(),
    workflow_execution_task_queue := unicode:chardata(),
    %% from WorkflowExecutionStartedEventAttributes:
    workflow_type := unicode:chardata(),
    task_queue := unicode:chardata(),
    workflow_execution_timeout_msec := erlang:timeout(),
    workflow_run_timeout_msec := erlang:timeout(),
    workflow_task_timeout_msec := erlang:timeout(),
    last_completion_result => temporal_sdk:term_from_payloads(),
    attempt := pos_integer(),
    memo => temporal_sdk:term_from_mapstring_payload(),
    search_attributes => temporal_sdk:term_from_mapstring_payload(),
    header => temporal_sdk:term_from_mapstring_payload()
}.
-export_type([context_workflow_info/0]).

-doc #{group => "Workflow behaviour"}.
-callback execute(Context :: context(), Input :: temporal_sdk:term_from_payloads()) ->
    ExecutionResult :: execution_result().

-doc #{group => "Workflow behaviour"}.
-callback handle_message(MessageName :: unicode:chardata(), MessageValue :: term()) ->
    {record, MarkerValue :: temporal_sdk:term_to_payloads()}
    | {fail, {
        Message :: temporal_sdk:serializable(),
        Source :: temporal_sdk:serializable(),
        Stacktrace :: temporal_sdk:serializable()
    }}
    | ignore.

-doc #{group => "Workflow behaviour"}.
-callback handle_failure(
    Class :: error | exit | throw, Reason :: term(), Stacktrace :: erlang:raise_stacktrace()
) ->
    ignore
    | ApplicationFailure ::
        temporal_sdk:application_failure()
        | temporal_sdk:user_application_failure().

-doc #{group => "Workflow behaviour"}.
-callback handle_query(
    HistoryEvents :: [temporal_sdk_workflow:history_event()],
    WorkflowQuery :: #{
        query_type := unicode:chardata(),
        query_args => temporal_sdk:term_from_payloads(),
        header => temporal_sdk:term_from_mapstring_payload()
    }
) ->
    #{answer := temporal_sdk:term_to_payloads()}
    | #{
        error_message => unicode:chardata(),
        failure =>
            temporal_sdk:application_failure()
            | temporal_sdk:user_application_failure(),
        cause => ?TEMPORAL_SPEC:'temporal.api.enums.v1.WorkflowTaskFailedCause'()
    }.

-optional_callbacks([
    handle_message/2,
    handle_failure/3,
    handle_query/2
]).

%% -------------------------------------------------------------------------------------------------
%% Temporal commands

-doc #{group => "Temporal commands"}.
-spec start_activity(
    ActivityType :: unicode:chardata() | atom(), Input :: temporal_sdk:term_to_payloads()
) ->
    activity() | no_return().
% eqwalizer:ignore
start_activity(ActivityType, Input) -> start_activity(ActivityType, Input, []).

-doc #{group => "Temporal commands"}.
-spec start_activity(
    ActivityType :: unicode:chardata() | atom(),
    Input :: temporal_sdk:term_to_payloads(),
    Opts :: start_activity_opts()
) -> activity() | activity_data() | no_return().
start_activity(ActivityType, Input, Opts) ->
    MsgName = 'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes',
    #{worker_opts := #{task_queue := WorkerTQ, task_settings := TaskSettings}} = ApiCtx = ?API_CTX,
    DftId =
        case proplists:is_defined(activity_id, Opts) of
            true -> '$_optional';
            false -> ActivityType
        end,
    DftEvent =
        case proplists:get_value(direct_result, Opts, false) of
            true -> result;
            _ -> close
        end,
    DefaultOpts =
        [
            {activity_id, [unicode, atom], '$_optional'},
            {task_queue, [unicode, atom], '$_optional'},
            {header, header, '$_optional', {MsgName, header}},
            %% temporal.api.common.v1.Payloads input = 6;
            {schedule_to_close_timeout, duration, '$_optional'},
            {schedule_to_start_timeout, duration, '$_optional'},
            {start_to_close_timeout, duration, '$_optional'},
            {heartbeat_timeout, duration, '$_optional'},
            {retry_policy, retry_policy, '$_optional'},
            {eager_execution, boolean,
                proplists:get_value(direct_execution, Opts, false) orelse
                    proplists:get_value(direct_result, Opts, false)},
            {use_workflow_build_id, boolean, '$_optional'},
            {priority, map, '$_optional'},
            %% SDK
            {raw_request, map, #{}},
            {awaitable_id, [unicode, atom, map], DftId},
            {awaitable_event, atom, DftEvent},
            {wait, boolean, false},
            {direct_execution, boolean, proplists:get_value(direct_result, Opts, false)},
            {direct_result, boolean, false},
            {session_execution, boolean, false},
            {node_execution_fun, function, '$_optional'}
        ],
    #{
        raw_request := RawRequest,
        eager_execution := EExec,
        direct_execution := DExec,
        session_execution := SExec,
        direct_result := DRes
    } =
        OptsAttr0 =
        maybe
            {ok, O} ?= temporal_sdk_utils_opts:build(DefaultOpts, Opts, ?API_CTX),
            ok ?= check_opts(start_activity, DefaultOpts),
            O
        else
            Err -> erlang:error(Err, [ActivityType, Input, Opts])
        end,
    #{task_queue := TQ} =
        OptsAttr1 =
        case OptsAttr0 of
            #{task_queue := _} ->
                OptsAttr0;
            #{session_execution := true} ->
                case TaskSettings of
                    #{session_worker := #{task_queue := SessionTQ}} ->
                        OptsAttr0#{task_queue => SessionTQ};
                    _ ->
                        erlang:error("Session execution requires session worker.", [
                            ActivityType, Input, Opts
                        ])
                end;
            #{} ->
                OptsAttr0#{task_queue => WorkerTQ}
        end,
    OptsAttr2 =
        case OptsAttr1 of
            #{schedule_to_close_timeout := _} ->
                OptsAttr1;
            #{start_to_close_timeout := _} ->
                OptsAttr1;
            #{heartbeat_timeout := HT} ->
                T = temporal_sdk_utils_time:msec_to_protobuf(
                    temporal_sdk_utils_time:protobuf_to_msec(HT) *
                        ?DEFAULT_ACTIVITY_START_TO_CLOSE_TIMEOUT_HEARTBEAT_MULTIPLICATION
                ),
                OptsAttr1#{start_to_close_timeout => T};
            #{direct_execution := true} ->
                OptsAttr1#{
                    start_to_close_timeout =>
                        ?DEFAULT_ACTIVITY_START_TO_CLOSE_TIMEOUT_DIRECT_EXECUTION
                };
            #{} ->
                OptsAttr1#{start_to_close_timeout => ?DEFAULT_ACTIVITY_START_TO_CLOSE_TIMEOUT}
        end,
    OptsAttr3 =
        case OptsAttr2 of
            #{direct_execution := true} -> OptsAttr2#{request_eager_execution => true};
            #{direct_result := true} -> OptsAttr2#{request_eager_execution => true};
            #{eager_execution := true} -> OptsAttr2#{request_eager_execution => true};
            #{} -> OptsAttr2
        end,
    OptsAttr = OptsAttr3#{input => temporal_sdk_api:map_to_payloads(ApiCtx, MsgName, input, Input)},

    {IdxKey, {activity, AIdC} = IdxKeyCasted} = temporal_sdk_api_awaitable:gen_idx(
        OptsAttr0,
        [activity],
        ?EXECUTION_ID,
        ?AWAIT_COUNTER,
        ?COMMANDS,
        ApiCtx,
        MsgName
    ),

    AT =
        case is_atom(ActivityType) of
            true -> atom_to_list(ActivityType);
            false -> ActivityType
        end,

    AttrOpts = maps:without(
        [
            raw_request,
            awaitable_id,
            awaitable_event,
            wait,
            eager_execution,
            direct_execution,
            direct_result,
            session_execution,
            node_execution_fun
        ],
        OptsAttr#{
            activity_type => #{name => AT},
            task_queue := #{name => TQ},
            activity_id => AIdC
        }
    ),
    HeaderSDKData =
        case OptsAttr of
            #{node_execution_fun := NEF} ->
                #{otel_context => ?OTEL_CONTEXT, node_execution_fun => NEF};
            #{} ->
                #{otel_context => ?OTEL_CONTEXT}
        end,
    % eqwalizer:ignore
    Attr1 = temporal_sdk_api_header:put_sdk(AttrOpts, HeaderSDKData, MsgName, ApiCtx),
    Attr = maps:merge(Attr1, RawRequest),

    IndexValue1 = #{
        state => cmd,
        execution_id => ?EXECUTION_ID,
        task_queue => TQ,
        activity_type => ActivityType,
        session_execution => SExec,
        eager_execution => EExec orelse DExec,
        direct_execution => DExec,
        direct_result => DRes
    },
    IndexValue =
        case OptsAttr of
            #{heartbeat_timeout := HT1} ->
                IndexValue1#{heartbeat_timeout => temporal_sdk_utils_time:protobuf_to_msec(HT1)};
            #{} ->
                IndexValue1
        end,

    case OptsAttr of
        #{request_eager_execution := true} ->
            #{cluster := ACC, worker_opts := ACWO} = ?API_CTX_ACTIVITY,
            case temporal_sdk_poller_adapter_utils:validate_temporal_task_name(ACC, ACWO, AT) of
                {ok, _Mod} -> ok;
                ModErr -> erlang:error(ModErr, [ActivityType, Input, Opts])
            end;
        #{} ->
            ok
    end,
    Cmd = temporal_sdk_api_command:schedule_activity_task_command(Attr),
    do_command(IdxKey, IdxKeyCasted, IndexValue, Cmd, OptsAttr0).

%% Activities started and canceled in the same task cycle are canceled by Temporal server
%% immeadiately, that is handle_heartbeat and handle_cancel will not be called. Additionally
%% details field is set by Temporal server to: `[~"ACTIVITY_ID_NOT_STARTED"]`.

-doc #{group => "Temporal commands"}.
-spec cancel_activity(ActivityOrActivityData :: activity() | activity_data()) ->
    activity() | no_return().
cancel_activity(Activity) when is_tuple(Activity) ->
    % eqwalizer:ignore
    cancel_activity(Activity, []);
cancel_activity(#{state := _} = ActivityData) ->
    fail_cancel_from_data(activity, ActivityData, []).

-doc #{group => "Temporal commands"}.
-spec cancel_activity(
    ActivityOrActivityData :: activity() | activity_data(),
    Opts ::
        [
            {awaitable_event, [cmd | cancel_request | result | schedule | start | close]}
            | {wait, boolean()}
            | wait
        ]
) -> activity() | activity_data() | no_return().
cancel_activity(Activity, Opts) when is_tuple(Activity) ->
    DefaultOpts =
        [
            {awaitable_event, atom, close},
            {wait, boolean, false}
        ],
    case temporal_sdk_utils_opts:build(DefaultOpts, Opts) of
        {ok, OptsAttr} ->
            {IdxKey0, IdxKeyCasted} = temporal_sdk_api_awaitable_index:cast_key(Activity, ?API_CTX),
            IdxKey = temporal_sdk_api_awaitable_index:set_event(IdxKey0, OptsAttr),
            do_command(IdxKey, IdxKeyCasted, #{cancel_requested => true}, sdk_command, OptsAttr);
        Err ->
            erlang:error(Err, [Activity, Opts])
    end;
cancel_activity(#{state := _} = ActivityData, Opts) ->
    fail_cancel_from_data(activity, ActivityData, Opts).

-doc #{group => "Temporal commands"}.
-spec record_marker(MarkerValueFun :: record_marker_value_fun()) ->
    marker() | no_return().
record_marker(MarkerValueFun) ->
    % eqwalizer:ignore
    record_marker(MarkerValueFun, []).

-doc #{group => "Temporal commands"}.
-spec record_marker(MarkerValueFun :: record_marker_value_fun(), Opts :: record_marker_opts()) ->
    marker() | marker_data() | no_return().
record_marker(MarkerValueFun, Opts) ->
    MsgName = 'temporal.api.command.v1.RecordMarkerCommandAttributes',
    DftType = proplists:get_value(type, Opts, ?DEFAULT_MARKER_TYPE),
    DftId =
        case proplists:is_defined(marker_name, Opts) of
            true ->
                '$_optional';
            false ->
                case proplists:get_value(mutable, Opts, '$_undefined') of
                    '$_undefined' -> DftType;
                    _ -> temporal_sdk_utils_path:string_path(["mutable", DftType], ":")
                end
        end,
    DftEvent =
        case proplists:get_value(mutable, Opts, false) of
            false -> value;
            _ -> close
        end,
    DefaultOpts = [
        {marker_name, [unicode, atom], '$_optional'},
        {header, header, '$_optional', {MsgName, header}},
        %% SDK
        {awaitable_id, [unicode, atom, map], DftId},
        {awaitable_event, atom, DftEvent},
        {wait, boolean, false},
        {type, any, DftType},
        {details, map, #{}},
        {mutable, [boolean, map], false},
        {value_codec, [atom, tuple], none}
    ],
    #{type := Type, details := Details} =
        OptsAttr =
        maybe
            {ok, O} ?= temporal_sdk_utils_opts:build(DefaultOpts, Opts, ?API_CTX),
            ok ?= check_opts(record_marker, O),
            O
        else
            Err -> erlang:error(Err, [MarkerValueFun, Opts])
        end,
    {IdxKey, IdxKeyCasted} = temporal_sdk_api_awaitable:gen_idx(
        OptsAttr, [marker, Type], ?EXECUTION_ID, ?AWAIT_COUNTER, ?COMMANDS, ?API_CTX, MsgName
    ),
    CmdOpts = parse_mutable_opt(OptsAttr),
    Cmd = #{value_fun => MarkerValueFun, opts => CmdOpts},
    IndexValue1 = #{state => cmd, execution_id => ?EXECUTION_ID, details => Details},
    IndexValue =
        case CmdOpts of
            #{mutable := false} -> IndexValue1;
            #{mutable := _} -> IndexValue1#{mutable => true}
        end,
    do_command(IdxKey, IdxKeyCasted, IndexValue, Cmd, OptsAttr).

parse_mutable_opt(#{mutable := #{mutations_limit := _, fail_on_limit := _}} = O) ->
    O;
parse_mutable_opt(#{mutable := #{mutations_limit := _} = M} = O) ->
    O#{mutable := M#{fail_on_limit => true}};
parse_mutable_opt(#{mutable := #{fail_on_limit := _} = M} = O) ->
    O#{mutable := M#{mutations_limit => 1}};
parse_mutable_opt(#{mutable := true} = O) ->
    O#{mutable := #{mutations_limit => 1, fail_on_limit => true}};
parse_mutable_opt(#{mutable := false} = O) ->
    O.

-doc #{group => "Temporal commands"}.
-spec start_timer(StartToFireTimeout :: temporal_sdk:time()) -> timer() | no_return().
start_timer({T, U}) when is_integer(T), T >= 0, is_atom(U) ->
    % eqwalizer:ignore
    start_timer(temporal_sdk_utils_time:convert_to_msec(T, U), []);
start_timer(T) when is_integer(T), T >= 0 ->
    % eqwalizer:ignore
    start_timer(T, []).

-doc #{group => "Temporal commands"}.
-spec start_timer(StartToFireTimeout :: temporal_sdk:time(), Opts :: start_timer_opts()) ->
    timer() | timer_data() | no_return().
start_timer({T, U}, Opts) when is_integer(T), T >= 0, is_atom(U) ->
    start_timer(temporal_sdk_utils_time:convert_to_msec(T, U), Opts);
start_timer(T, Opts) when is_integer(T), T >= 0 ->
    MsgName = 'temporal.api.command.v1.StartTimerCommandAttributes',
    DftId =
        case proplists:is_defined(time_id, Opts) of
            true -> '$_optional';
            false -> noname
        end,
    DefaultOpts =
        [
            {timer_id, [unicode, atom], '$_optional'},
            %% SDK
            {awaitable_id, [unicode, atom, map], DftId},
            {awaitable_event, atom, close},
            {wait, boolean, false}
        ],
    case temporal_sdk_utils_opts:build(DefaultOpts, Opts) of
        {ok, OptsAttr} ->
            {IdxKey, {timer, TIdC} = IdxKeyCasted} = temporal_sdk_api_awaitable:gen_idx(
                OptsAttr, [timer], ?EXECUTION_ID, ?AWAIT_COUNTER, ?COMMANDS, ?API_CTX, MsgName
            ),
            Attr = #{
                timer_id => TIdC,
                start_to_fire_timeout => temporal_sdk_utils_time:msec_to_protobuf(T)
            },
            IndexValue = #{state => cmd, execution_id => ?EXECUTION_ID},
            Cmd = temporal_sdk_api_command:start_timer_command(Attr),
            do_command(IdxKey, IdxKeyCasted, IndexValue, Cmd, OptsAttr);
        Err ->
            erlang:error(Err, [T, Opts])
    end.

-doc #{group => "Temporal commands"}.
-spec cancel_timer(
    TimerOrTimerDataOrTimerId :: timer() | timer_data() | unicode:chardata() | atom()
) ->
    timer() | no_return().
cancel_timer(Timer) when is_tuple(Timer) ->
    % eqwalizer:ignore
    cancel_timer(Timer, []);
cancel_timer(#{state := _} = TimerData) ->
    % eqwalizer:ignore
    cancel_timer(TimerData, []);
cancel_timer(TimerId) ->
    % eqwalizer:ignore
    cancel_timer({timer, TimerId}, []).

-doc #{group => "Temporal commands"}.
-spec cancel_timer(
    TimerOrTimerDataOrTimerId :: timer() | timer_data() | unicode:chardata() | atom(),
    Opts ::
        [
            {awaitable_event, [cmd | cancel_request | result | schedule | start | close]}
            | {wait, boolean()}
            | wait
        ]
) -> timer() | timer_data() | no_return().
cancel_timer(Timer, Opts) when is_tuple(Timer) ->
    DefaultOpts =
        [
            {awaitable_event, atom, close},
            {wait, boolean, false}
        ],
    case temporal_sdk_utils_opts:build(DefaultOpts, Opts) of
        {ok, OptsAttr} ->
            IdxKeyCasted = temporal_sdk_api_awaitable_index:cast(Timer, ?API_CTX),
            IdxKey = temporal_sdk_api_awaitable_index:set_event(Timer, OptsAttr),
            do_command(IdxKey, IdxKeyCasted, #{cancel_requested => true}, sdk_command, OptsAttr);
        Err ->
            erlang:error(Err, [Timer, Opts])
    end;
cancel_timer(#{state := _} = TimerData, Opts) ->
    fail_cancel_from_data(timer, TimerData, Opts);
cancel_timer(TimerId, Opts) ->
    cancel_timer({timer, TimerId}, Opts).

-doc #{group => "Temporal commands"}.
-spec start_child_workflow(
    TaskQueue :: unicode:chardata(), WorkflowType :: atom() | unicode:chardata()
) -> child_workflow() | child_workflow_data() | no_return().
start_child_workflow(TaskQueue, WorkflowType) ->
    start_child_workflow(TaskQueue, WorkflowType, []).

-doc #{group => "Temporal commands"}.
-spec start_child_workflow(
    TaskQueue :: unicode:chardata(),
    WorkflowType :: atom() | unicode:chardata(),
    Opts :: start_child_workflow_opts()
) -> child_workflow() | child_workflow_data() | no_return().
start_child_workflow(TaskQueue, WorkflowType, Opts) when is_atom(WorkflowType) ->
    start_child_workflow(TaskQueue, atom_to_list(WorkflowType), Opts);
start_child_workflow(TaskQueue, WorkflowType, Opts) ->
    MsgName = 'temporal.api.command.v1.StartChildWorkflowExecutionCommandAttributes',
    DftId =
        case proplists:is_defined(workflow_id, Opts) of
            true -> '$_optional';
            false -> WorkflowType
        end,
    DefaultOpts = [
        {namespace, unicode, "default"},
        {workflow_id, [unicode, atom], '$_optional'},
        %% temporal.api.common.v1.WorkflowType workflow_type = 3;
        %% temporal.api.taskqueue.v1.TaskQueue task_queue = 4;
        {input, payloads, '$_optional', {MsgName, input}},
        {workflow_execution_timeout, duration, '$_optional'},
        {workflow_run_timeout, duration, '$_optional'},
        {workflow_task_timeout, duration, '$_optional'},
        {parent_close_policy, atom, '$_optional'},
        {workflow_id_reuse_policy, atom, '$_optional'},
        {retry_policy, retry_policy, '$_optional'},
        {cron_schedule, unicode, '$_optional'},
        {header, header, '$_optional', {MsgName, header}},
        {memo, memo, '$_optional', {MsgName, [memo, fields]}},
        {search_attributes, search_attributes, '$_optional',
            {MsgName, [search_attributes, indexed_fields]}},
        {priority, map, '$_optional'},
        %% SDK
        {raw_request, map, #{}},
        {awaitable_id, [unicode, atom, map], DftId},
        {awaitable_event, atom, close},
        {wait, boolean, false}
    ],
    case temporal_sdk_utils_opts:build(DefaultOpts, Opts, ?API_CTX) of
        {ok, #{namespace := NS} = FullOpts} ->
            {IdxKey, {child_workflow, WIdC} = IdxKeyCasted} =
                temporal_sdk_api_awaitable:gen_idx(
                    FullOpts,
                    [child_workflow],
                    ?EXECUTION_ID,
                    ?AWAIT_COUNTER,
                    ?COMMANDS,
                    ?API_CTX,
                    MsgName
                ),
            ReqFromOpts = maps:without(
                [raw_request, awaitable_id, awaitable_event, wait], FullOpts
            ),
            WT =
                case is_atom(WorkflowType) of
                    true -> atom_to_list(WorkflowType);
                    false -> WorkflowType
                end,
            Req = ReqFromOpts#{
                workflow_type => #{name => WT},
                task_queue => #{name => TaskQueue},
                workflow_id => WIdC
            },
            IdxValue = #{
                state => cmd,
                execution_id => ?EXECUTION_ID,
                task_queue => TaskQueue,
                workflow_type => WorkflowType,
                namespace => NS
            },
            Cmd = temporal_sdk_api_command:start_child_workflow_command(Req),
            do_command(IdxKey, IdxKeyCasted, IdxValue, Cmd, FullOpts);
        Err ->
            erlang:error(Err, [TaskQueue, WorkflowType, Opts])
    end.

-doc #{group => "Temporal commands"}.
-spec start_nexus(
    Endpoint :: atom() | unicode:chardata(),
    Service :: atom() | unicode:chardata(),
    Operation :: atom() | unicode:chardata(),
    Input :: temporal_sdk:term_to_payload()
) -> nexus().
start_nexus(Endpoint, Service, Operation, Input) ->
    start_nexus(Endpoint, Service, Operation, Input, []).

-doc #{group => "Temporal commands"}.
-spec start_nexus(
    Endpoint :: atom() | unicode:chardata(),
    Service :: atom() | unicode:chardata(),
    Operation :: atom() | unicode:chardata(),
    Input :: temporal_sdk:term_to_payload(),
    Opts :: start_nexus_opts()
) -> nexus().
start_nexus(Endpoint, Service, Operation, Input, Opts) ->
    MsgName = 'temporal.api.command.v1.ScheduleNexusOperationCommandAttributes',
    DefaultOpts = [{schedule_to_close_timeout, duration, '$_optional'}],
    case temporal_sdk_utils_opts:build(DefaultOpts, Opts) of
        {ok, O} ->
            H = #{otel_context => ?OTEL_CONTEXT},
            Header = #{?TASK_HEADER_KEY_SDK_DATA => base64:encode(erlang:term_to_binary(H))},
            Attr = O#{
                input => temporal_sdk_api:map_to_payload(?API_CTX, MsgName, input, Input),
                nexus_header => Header
            },
            IdxKeyUser = {nexus, Endpoint, Service, Operation},
            IdxKey = temporal_sdk_api_awaitable_index:cast(
                {nexus, Endpoint, Service, Operation}, ?API_CTX
            ),
            IdxValue = #{state => cmd, execution_id => ?EXECUTION_ID, input => Input},
            Cmd = temporal_sdk_api_command:schedule_nexus_operation(IdxKey, Attr),
            do_command(IdxKey, IdxKeyUser, IdxValue, Cmd, O);
        Err ->
            erlang:error(Err, [Endpoint, Service, Operation, Input, Opts])
    end.

-doc #{group => "Temporal commands"}.
-spec modify_workflow_properties(
    UpsertedMemoFields :: temporal_sdk:term_to_mapstring_payload()
) ->
    workflow_properties() | no_return().
modify_workflow_properties(UpsertedMemoFields) ->
    % eqwalizer:ignore
    modify_workflow_properties(UpsertedMemoFields, []).

-doc #{group => "Temporal commands"}.
-spec modify_workflow_properties(
    UpsertedMemoFields :: temporal_sdk:term_to_mapstring_payload(),
    Opts :: [{awaitable_event, [cmd | close]} | {wait, boolean()} | wait]
) ->
    workflow_properties() | workflow_properties_data() | no_return().
modify_workflow_properties(UpsertedMemoFields, Opts) ->
    DefaultOpts = [{awaitable_event, atom, close}, {wait, boolean, false}],
    case temporal_sdk_utils_opts:build(DefaultOpts, Opts) of
        {ok, OptsAttr} ->
            MsgName = 'temporal.api.command.v1.ModifyWorkflowPropertiesCommandAttributes',
            Attr = #{
                upserted_memo => #{
                    fields =>
                        temporal_sdk_api:map_to_mapstring_payload(
                            ?API_CTX, MsgName, [upserted_memo, fields], UpsertedMemoFields
                        )
                }
            },
            IdxKey = {workflow_properties},
            IdxValue = #{
                state => cmd, execution_id => ?EXECUTION_ID, upserted_memo => UpsertedMemoFields
            },
            Cmd = temporal_sdk_api_command:modify_workflow_properties_command(Attr),
            do_command(IdxKey, IdxKey, IdxValue, Cmd, OptsAttr);
        Err ->
            erlang:error(Err, [UpsertedMemoFields, Opts])
    end.

-doc #{group => "Temporal commands"}.
-spec complete_workflow_execution(Result :: temporal_sdk:term_to_payloads()) ->
    complete_workflow_execution().
complete_workflow_execution(Result) ->
    IdxKey = {complete_workflow_execution},
    IdxValue = #{state => cmd, execution_id => ?EXECUTION_ID, result => Result},
    Cmd = temporal_sdk_api_command:complete_workflow_execution_command(?API_CTX, Result),
    do_command(IdxKey, IdxKey, IdxValue, Cmd, #{wait => true}).

-doc #{group => "Temporal commands"}.
-spec cancel_workflow_execution(Details :: temporal_sdk:term_to_payloads()) ->
    cancel_workflow_execution().
cancel_workflow_execution(Details) ->
    IdxKey = {cancel_workflow_execution},
    IdxValue = #{state => cmd, execution_id => ?EXECUTION_ID, details => Details},
    Cmd = temporal_sdk_api_command:cancel_workflow_execution_command(?API_CTX, Details),
    do_command(IdxKey, IdxKey, IdxValue, Cmd, #{wait => true}).

-doc #{group => "Temporal commands"}.
-spec fail_workflow_execution(
    ApplicationFailure ::
        temporal_sdk:application_failure()
        | temporal_sdk:user_application_failure()
) -> fail_workflow_execution().
fail_workflow_execution(ApplicationFailure) ->
    case temporal_sdk_api_failure:build(?API_CTX, ApplicationFailure) of
        {ok, AF} ->
            IdxKey = {fail_workflow_execution},
            IdxValue =
                #{state => cmd, execution_id => ?EXECUTION_ID, failure => ApplicationFailure},
            Cmd = temporal_sdk_api_command:fail_workflow_execution_command(?API_CTX, AF),
            do_command(IdxKey, IdxKey, IdxValue, Cmd, #{wait => true});
        Err ->
            erlang:error(Err, [ApplicationFailure])
    end.

-doc #{group => "Temporal commands"}.
-spec continue_as_new_workflow(
    TaskQueue :: unicode:chardata(),
    WorkflowType :: atom() | unicode:chardata()
) -> continue_as_new_workflow().
continue_as_new_workflow(TaskQueue, WorkflowType) ->
    continue_as_new_workflow(TaskQueue, WorkflowType, []).

-doc #{group => "Temporal commands"}.
-spec continue_as_new_workflow(
    TaskQueue :: unicode:chardata(),
    WorkflowType :: atom() | unicode:chardata(),
    Opts :: continue_as_new_workflow_opts()
) -> continue_as_new_workflow().
continue_as_new_workflow(TaskQueue, WorkflowType, Opts) when is_atom(WorkflowType) ->
    continue_as_new_workflow(TaskQueue, atom_to_list(WorkflowType), Opts);
continue_as_new_workflow(TaskQueue, WorkflowType, Opts) ->
    MsgName = 'temporal.api.command.v1.ContinueAsNewWorkflowExecutionCommandAttributes',
    DefaultOpts = [
        %% temporal.api.common.v1.WorkflowType workflow_type = 1;
        %% temporal.api.taskqueue.v1.TaskQueue task_queue = 2;
        {input, payloads, '$_optional', {MsgName, input}},
        {workflow_run_timeout, duration, '$_optional'},
        {workflow_task_timeout, duration, '$_optional'},
        {backoff_start_interval, duration, '$_optional'},
        {retry_policy, retry_policy, '$_optional'},
        {header, header, '$_optional', {MsgName, header}},
        {memo, memo, '$_optional', {MsgName, [memo, fields]}},
        {search_attributes, search_attributes, '$_optional',
            {MsgName, [search_attributes, indexed_fields]}}
    ],
    case temporal_sdk_utils_opts:build(DefaultOpts, Opts, ?API_CTX) of
        {ok, ReqFromOpts} ->
            Req = ReqFromOpts#{
                workflow_type => #{name => WorkflowType},
                task_queue => #{name => TaskQueue}
            },
            IdxKey = {continue_as_new_workflow},
            IdxValue = #{
                state => cmd,
                execution_id => ?EXECUTION_ID,
                task_queue => TaskQueue,
                workflow_type => WorkflowType
            },
            Cmd = temporal_sdk_api_command:continue_as_new_workflow_command(?API_CTX, Req),
            do_command(IdxKey, IdxKey, IdxValue, Cmd, #{wait => true});
        Err ->
            erlang:error(Err, [TaskQueue, WorkflowType, Opts])
    end.

%% -------------------------------------------------------------------------------------------------
%% Temporal external commands

-doc #{group => "Temporal external commands"}.
-spec admit_signal(SignalOrSignalName :: signal() | unicode:chardata()) -> signal().
admit_signal({S, _} = Signal) when S =:= signal; S =:= signal_request, S =:= signal_admit ->
    % eqwalizer:ignore
    admit_signal(Signal, []);
admit_signal(SignalName) ->
    % eqwalizer:ignore
    admit_signal({signal, SignalName}, []).

-doc #{group => "Temporal external commands"}.
-spec admit_signal(
    SignalOrSignalName :: signal() | unicode:chardata(), Opts :: admit_signal_opts()
) -> signal() | signal_data().
admit_signal({S, _} = Signal, Opts) when S =:= signal; S =:= signal_request, S =:= signal_admit ->
    DefaultOpts = [
        {details, any, '$_optional'},
        %% SDK
        {awaitable_event, atom, admit},
        {wait, boolean, false}
    ],
    case temporal_sdk_utils_opts:build(DefaultOpts, Opts) of
        {ok, #{awaitable_event := AE} = Attr} ->
            {{_, SN}, IdxKeyCasted} = temporal_sdk_api_awaitable_index:cast_key(Signal, ?API_CTX),
            IdxKey = {temporal_sdk_api_awaitable_index:to_event(signal, AE), SN},
            IdxVal = maps:merge(maps:with([details], Attr), #{state => admitted}),
            do_command(IdxKey, IdxKeyCasted, IdxVal, sdk_command, Attr);
        Err ->
            erlang:error(Err, [Signal, Opts])
    end;
admit_signal(SignalName, Opts) ->
    % eqwalizer:ignore
    admit_signal({signal, SignalName}, Opts).

%% special queries: ~"__temporal_workflow_metadata", ~"__stack_trace"
-doc #{group => "Temporal external commands"}.
-spec respond_query(QueryOrQueryType :: query() | unicode:chardata(), Opts :: respond_query_opts()) ->
    query() | query_data().
respond_query({Q, _} = Query, Opts) when Q =:= query; Q =:= query_request; Q =:= query_response ->
    MsgName = 'temporal.api.workflowservice.v1.RespondQueryTaskCompletedRequest',
    ApiCtx = ?API_CTX,
    DefaultOpts =
        [
            {answer, payloads, '$_optional', {MsgName, answer}},
            {error_message, unicode, '$_optional'},
            {failure, failure, '$_optional'},
            %% SDK
            {awaitable_event, atom, response},
            {wait, boolean, false}
        ],
    maybe
        {ok, #{awaitable_event := AE} = Attr} ?=
            temporal_sdk_utils_opts:build(DefaultOpts, Opts, ApiCtx),
        ok ?= check_opts(respond_query, Attr),
        {{_, QN}, IdxKeyCasted} = temporal_sdk_api_awaitable_index:cast_key(Query, ApiCtx),
        IdxKey = {temporal_sdk_api_awaitable_index:to_event(query, AE), QN},
        Response = maps:with([answer, error_message, failure], Attr),
        IdxVal = maps:with([answer, error_message, failure], proplists:to_map(Opts)),
        do_command(IdxKey, IdxKeyCasted, {IdxVal, Response}, sdk_command, Attr)
    else
        Err -> erlang:error(Err, [Query, Opts])
    end;
respond_query(QueryType, Opts) ->
    respond_query({query, QueryType}, Opts).

%% -------------------------------------------------------------------------------------------------
%% Temporal marker commands

-doc #{group => "Temporal marker commands"}.
-spec record_uuid4() -> marker() | no_return().
record_uuid4() ->
    % eqwalizer:ignore
    record_uuid4([]).

-doc #{group => "Temporal marker commands"}.
-spec record_uuid4(Opts :: record_marker_opts()) -> marker() | marker_data() | no_return().
record_uuid4(Opts) ->
    record_marker(fun() -> temporal_sdk_utils:uuid4() end, add_marker_type(uuid4, Opts)).

-doc #{group => "Temporal marker commands"}.
-spec record_system_time() -> marker() | no_return().
record_system_time() ->
    % eqwalizer:ignore
    record_system_time([]).

-doc #{group => "Temporal marker commands"}.
-spec record_system_time(UnitOrOpts :: erlang:time_unit() | record_marker_opts()) ->
    marker() | marker_data() | no_return().
record_system_time(Unit) when is_atom(Unit) ->
    record_marker(fun() -> erlang:system_time(Unit) end, add_marker_li_ser(system_time, []));
record_system_time(Opts) when is_list(Opts) ->
    record_marker(fun() -> erlang:system_time() end, add_marker_li_ser(system_time, Opts)).

-doc #{group => "Temporal marker commands"}.
-spec record_system_time(Unit :: erlang:time_unit(), Opts :: record_marker_opts()) ->
    marker() | marker_data() | no_return().
record_system_time(Unit, Opts) ->
    record_marker(fun() -> erlang:system_time(Unit) end, add_marker_li_ser(system_time, Opts)).

-doc #{group => "Temporal marker commands"}.
-spec record_rand_uniform() -> marker() | no_return().
record_rand_uniform() ->
    % eqwalizer:ignore
    record_rand_uniform([]).

-doc #{group => "Temporal marker commands"}.
-spec record_rand_uniform(RangeOrOpts :: pos_integer() | record_marker_opts()) ->
    marker() | marker_data() | no_return().
record_rand_uniform(Range) when is_integer(Range) ->
    record_marker(fun() -> rand:uniform(Range) end, add_marker_li_ser(rand_uniform, []));
record_rand_uniform(Opts) when is_list(Opts) ->
    record_marker(fun() -> rand:uniform() end, add_marker_li_ser(rand_uniform, Opts)).

-doc #{group => "Temporal marker commands"}.
-spec record_rand_uniform(Range :: pos_integer(), Opts :: record_marker_opts()) ->
    marker() | marker_data() | no_return().
record_rand_uniform(Range, Opts) ->
    record_marker(fun() -> rand:uniform(Range) end, add_marker_li_ser(rand_uniform, Opts)).

-doc #{group => "Temporal marker commands"}.
-spec record_env(Par :: atom()) -> marker() | no_return().
record_env(Par) when is_atom(Par) ->
    % eqwalizer:ignore
    record_env(Par, []).

-doc #{group => "Temporal marker commands"}.
-spec record_env(Par :: atom(), Opts :: record_marker_opts()) ->
    marker() | marker_data() | no_return().
record_env(Par, Opts) when is_atom(Par) ->
    record_marker(
        fun() ->
            case application:get_env(Par) of
                {ok, Val} -> Val;
                undefined -> "undefined"
            end
        end,
        add_marker_li_ser(env, Opts)
    ).

add_marker_type(Type, Opts) ->
    case proplists:is_defined(type, Opts) of
        true -> Opts;
        false -> [{type, Type} | Opts]
    end.

add_marker_li_ser(Type, Opts) ->
    case proplists:is_defined(value_codec, Opts) of
        true -> erlang:error("<value_codec> cannot be defined for this marker.", [Type, Opts]);
        false -> add_marker_type(Type, [{value_codec, list} | Opts])
    end.

%% -------------------------------------------------------------------------------------------------
%% Awaitables functions

-doc #{group => "Awaitables functions"}.
-spec await(AwaitPattern :: await_pattern()) -> await_ret().
await(AwaitPattern) ->
    temporal_sdk_executor:inc_await_counter(),
    {Pattern, PatternKey} = temporal_sdk_api_awaitable:cast_key(AwaitPattern, ?API_CTX),
    Match = temporal_sdk_api_awaitable:init_match(PatternKey, {?HISTORY_TABLE, ?INDEX_TABLE}),
    MatchTest = temporal_sdk_api_awaitable:match_test(Pattern, Match),
    case temporal_sdk_api_awaitable:is_ready(MatchTest) of
        true ->
            {ok, Match};
        false ->
            Commands = temporal_sdk_executor:set_commands([]),
            do_await(Pattern, PatternKey, Match, MatchTest, {?EXECUTION_IDX, Commands})
    end.

do_await(Pattern, PatternKey, Match, Test, CommandsOrState) ->
    case call_id({await, CommandsOrState}) of
        noevent ->
            R = temporal_sdk_api_awaitable:update_match(
                Pattern, PatternKey, Match, Test, ?INDEX_TABLE, ?HISTORY_TABLE
            ),
            case R of
                noop ->
                    {noevent, Match};
                {update, NewMatch, _NewTest} ->
                    {noevent, NewMatch};
                {ready, AwaitedMatch} ->
                    {ok, AwaitedMatch}
            end;
        complete_await ->
            R = temporal_sdk_api_awaitable:update_match(
                Pattern, PatternKey, Match, Test, ?INDEX_TABLE, ?HISTORY_TABLE
            ),
            case R of
                noop ->
                    do_await(Pattern, PatternKey, Match, Test, awaited);
                {update, NewMatch, NewTest} ->
                    do_await(Pattern, PatternKey, NewMatch, NewTest, awaited);
                {ready, AwaitedMatch} ->
                    {ok, AwaitedMatch}
            end
    end.

-doc #{group => "Awaitables functions"}.
-spec await(AwaitPattern :: await_pattern(), Timeout :: temporal_sdk:time()) -> await_ret().
await(AwaitPattern, {Timeout, TimeUnit}) when is_integer(Timeout) ->
    await(AwaitPattern, temporal_sdk_utils_time:convert_to_msec(Timeout, TimeUnit));
await(AwaitPattern, Timeout) when is_integer(Timeout) ->
    case is_awaited(AwaitPattern) of
        {true, QMatch} ->
            {ok, QMatch};
        {false, _NoMatch} ->
            Timer = start_timer(Timeout, [{awaitable_id, ?AWAIT_TIMEOUT_ID}]),
            case await_one([Timer, AwaitPattern]) of
                {ok, [#{state := S}, _Match]} when S =:= fired; S =:= canceled ->
                    case is_awaited(AwaitPattern) of
                        {true, CurrentMatch} ->
                            {ok, CurrentMatch};
                        {false, CurrentMatch} ->
                            {noevent, CurrentMatch}
                    end;
                {ok, [#{state := S}, Match]} when S =:= cmd; S =:= started ->
                    cancel_timer(Timer),
                    {ok, Match}
            end
    end.

-doc #{group => "Awaitables functions"}.
-spec await_one(AwaitPattern :: [await_pattern()]) -> await_ret_list().
await_one(AwaitPattern) when is_list(AwaitPattern) ->
    case await({one, AwaitPattern}) of
        {noevent, {one, AwaitMatchList}} when is_list(AwaitMatchList) -> {noevent, AwaitMatchList};
        {ok, {one, AwaitMatchList}} when is_list(AwaitMatchList) -> {ok, AwaitMatchList}
    end.

-doc #{group => "Awaitables functions"}.
-spec await_one(AwaitPattern :: [await_pattern()], Timeout :: temporal_sdk:time()) ->
    await_ret_list().
await_one(AwaitPattern, {Timeout, TimeUnit}) when is_integer(Timeout) ->
    await_one(AwaitPattern, temporal_sdk_utils_time:convert_to_msec(Timeout, TimeUnit));
await_one(AwaitPattern, Timeout) when is_list(AwaitPattern), is_integer(Timeout) ->
    case await({one, AwaitPattern}, Timeout) of
        {noevent, {one, AwaitMatchList}} when is_list(AwaitMatchList) -> {noevent, AwaitMatchList};
        {ok, {one, AwaitMatchList}} when is_list(AwaitMatchList) -> {ok, AwaitMatchList}
    end.

-doc #{group => "Awaitables functions"}.
-spec await_all(AwaitPattern :: [await_pattern()]) -> await_ret_list().
await_all(AwaitPattern) when is_list(AwaitPattern) ->
    case await({all, AwaitPattern}) of
        {noevent, {all, AwaitMatchList}} when is_list(AwaitMatchList) -> {noevent, AwaitMatchList};
        {ok, {all, AwaitMatchList}} when is_list(AwaitMatchList) -> {ok, AwaitMatchList}
    end.

-doc #{group => "Awaitables functions"}.
-spec await_all(AwaitPattern :: [await_pattern()], Timeout :: temporal_sdk:time()) ->
    await_ret_list().
await_all(AwaitPattern, {Timeout, TimeUnit}) when is_integer(Timeout) ->
    await_all(AwaitPattern, temporal_sdk_utils_time:convert_to_msec(Timeout, TimeUnit));
await_all(AwaitPattern, Timeout) when is_list(AwaitPattern), is_integer(Timeout) ->
    case await({all, AwaitPattern}, Timeout) of
        {noevent, {all, AwaitMatchList}} when is_list(AwaitMatchList) -> {noevent, AwaitMatchList};
        {ok, {all, AwaitMatchList}} when is_list(AwaitMatchList) -> {ok, AwaitMatchList}
    end.

-doc #{group => "Awaitables functions"}.
-spec await_info(InfoOrInfoId :: info() | term()) -> await_ret() | noinfo.
await_info({info, _InfoId} = Info) ->
    case await(Info) of
        {noevent, _} -> noinfo;
        {ok, Awaitable} when is_tuple(Awaitable) -> await(Awaitable)
    end;
await_info(InfoId) ->
    await_info({info, InfoId}).

-doc #{group => "Awaitables functions"}.
-spec await_info(
    InfoOrInfoId :: info() | term(),
    InfoTimeout :: temporal_sdk:time(),
    AwaitableTimeout :: temporal_sdk:time()
) -> await_ret() | noinfo.
await_info(Info, {ITimeout, ITimeUnit}, AwaitableTimeout) when is_integer(ITimeout) ->
    await_info(
        Info, temporal_sdk_utils_time:convert_to_msec(ITimeout, ITimeUnit), AwaitableTimeout
    );
await_info(Info, InfoTimeout, {ATimeout, ATimeUnit}) when is_integer(ATimeout) ->
    await_info(
        Info, InfoTimeout, temporal_sdk_utils_time:convert_to_msec(ATimeout, ATimeUnit)
    );
await_info({info, _InfoId} = Info, InfoTimeout, AwaitableTimeout) when
    is_integer(InfoTimeout), is_integer(AwaitableTimeout)
->
    case await(Info, InfoTimeout) of
        {noevent, _} -> noinfo;
        {ok, Awaitable} when is_tuple(Awaitable) -> await(Awaitable, AwaitableTimeout)
    end;
await_info(InfoId, InfoTimeout, AwaitableTimeout) ->
    await_info({info, InfoId}, InfoTimeout, AwaitableTimeout).

-doc #{group => "Awaitables functions"}.
-spec is_awaited(AwaitPattern :: await_pattern()) ->
    {true, await_match()} | {false, await_match()} | no_return.
is_awaited(AwaitPattern) ->
    {Pattern, PatternKey} = temporal_sdk_api_awaitable:cast_key(AwaitPattern, ?API_CTX),
    Match = temporal_sdk_api_awaitable:init_match(PatternKey, {?HISTORY_TABLE, ?INDEX_TABLE}),
    MatchTest = temporal_sdk_api_awaitable:match_test(Pattern, Match),
    case temporal_sdk_api_awaitable:is_ready(MatchTest) of
        true -> {true, Match};
        false -> {false, Match}
    end.

-doc #{group => "Awaitables functions"}.
-spec is_awaited_one(AwaitPattern :: [await_pattern()]) ->
    {true, [await_match()]} | {false, [await_match()]} | no_return.
is_awaited_one(AwaitPattern) ->
    case is_awaited({one, AwaitPattern}) of
        {R, {one, AwaitMatchList}} when is_list(AwaitMatchList) -> {R, AwaitMatchList}
    end.

-doc #{group => "Awaitables functions"}.
-spec is_awaited_all(AwaitPattern :: [await_pattern()]) ->
    {true, [await_match()]} | {false, [await_match()]} | no_return.
is_awaited_all(AwaitPattern) ->
    case is_awaited({all, AwaitPattern}) of
        {R, {all, AwaitMatchList}} when is_list(AwaitMatchList) -> {R, AwaitMatchList}
    end.

-doc #{group => "Awaitables functions"}.
-spec wait(AwaitPattern :: await_pattern()) -> await_match() | no_return().
wait(AwaitPattern) ->
    case await(AwaitPattern) of
        {ok, Match} ->
            Match;
        {noevent, PartialMatch} ->
            erlang:error(noevent, [{await_pattern, AwaitPattern}, {partial_match, PartialMatch}])
    end.

-doc #{group => "Awaitables functions"}.
-spec wait(AwaitPattern :: await_pattern(), Timeout :: temporal_sdk:time()) ->
    await_match() | no_return().
wait(AwaitPattern, {Timeout, TimeUnit}) when is_integer(Timeout) ->
    wait(AwaitPattern, temporal_sdk_utils_time:convert_to_msec(Timeout, TimeUnit));
wait(AwaitPattern, Timeout) when is_integer(Timeout) ->
    case await(AwaitPattern, Timeout) of
        {ok, Match} ->
            Match;
        {noevent, PartialMatch} ->
            erlang:error(noevent, [{await_pattern, AwaitPattern}, {partial_match, PartialMatch}])
    end.

-doc #{group => "Awaitables functions"}.
-spec wait_one(AwaitPattern :: [await_pattern()]) -> [await_match()] | no_return().
wait_one(AwaitPattern) when is_list(AwaitPattern) ->
    case await_one(AwaitPattern) of
        {ok, Match} ->
            Match;
        {noevent, PartialMatch} ->
            erlang:error(noevent, [{await_pattern, AwaitPattern}, {partial_match, PartialMatch}])
    end.

-doc #{group => "Awaitables functions"}.
-spec wait_one(AwaitPattern :: [await_pattern()], Timeout :: temporal_sdk:time()) ->
    [await_match()] | no_return().
wait_one(AwaitPattern, {Timeout, TimeUnit}) when is_integer(Timeout) ->
    wait_one(AwaitPattern, temporal_sdk_utils_time:convert_to_msec(Timeout, TimeUnit));
wait_one(AwaitPattern, Timeout) when is_list(AwaitPattern), is_integer(Timeout) ->
    case await_one(AwaitPattern, Timeout) of
        {ok, Match} ->
            Match;
        {noevent, PartialMatch} ->
            erlang:error(noevent, [{await_pattern, AwaitPattern}, {partial_match, PartialMatch}])
    end.

-doc #{group => "Awaitables functions"}.
-spec wait_all(AwaitPattern :: [await_pattern()]) -> [await_match()] | no_return().
wait_all(AwaitPattern) when is_list(AwaitPattern) ->
    case await_all(AwaitPattern) of
        {ok, Match} ->
            Match;
        {noevent, PartialMatch} ->
            erlang:error(noevent, [{await_pattern, AwaitPattern}, {partial_match, PartialMatch}])
    end.

-doc #{group => "Awaitables functions"}.
-spec wait_all(AwaitPattern :: [await_pattern()], Timeout :: temporal_sdk:time()) ->
    [await_match()] | no_return().
wait_all(AwaitPattern, {Timeout, TimeUnit}) when is_integer(Timeout) ->
    wait_all(AwaitPattern, temporal_sdk_utils_time:convert_to_msec(Timeout, TimeUnit));
wait_all(AwaitPattern, Timeout) when is_list(AwaitPattern), is_integer(Timeout) ->
    case await_all(AwaitPattern, Timeout) of
        {ok, Match} ->
            Match;
        {noevent, PartialMatch} ->
            erlang:error(noevent, [{await_pattern, AwaitPattern}, {partial_match, PartialMatch}])
    end.

-doc #{group => "Awaitables functions"}.
-spec wait_info(InfoOrInfoId :: info() | term()) -> await_match() | no_return().
wait_info({info, _InfoId} = Info) ->
    case await(Info) of
        {noevent, _} -> erlang:error(noinfo, [Info]);
        {ok, Awaitable} when is_tuple(Awaitable) -> wait(Awaitable)
    end;
wait_info(InfoId) ->
    wait_info({info, InfoId}).

-doc #{group => "Awaitables functions"}.
-spec wait_info(
    InfoOrInfoId :: info() | term(),
    InfoTimeout :: temporal_sdk:time(),
    AwaitableTimeout :: temporal_sdk:time()
) -> await_match() | no_return().
wait_info(Info, {ITimeout, ITimeUnit}, AwaitableTimeout) when is_integer(ITimeout) ->
    wait_info(
        Info, temporal_sdk_utils_time:convert_to_msec(ITimeout, ITimeUnit), AwaitableTimeout
    );
wait_info(Info, InfoTimeout, {ATimeout, ATimeUnit}) when is_integer(ATimeout) ->
    wait_info(
        Info, InfoTimeout, temporal_sdk_utils_time:convert_to_msec(ATimeout, ATimeUnit)
    );
wait_info({info, _InfoId} = Info, InfoTimeout, AwaitableTimeout) when
    is_integer(InfoTimeout), is_integer(AwaitableTimeout)
->
    case await(Info, InfoTimeout) of
        {noevent, _} -> erlang:error(noinfo, [Info, InfoTimeout, AwaitableTimeout]);
        {ok, Awaitable} when is_tuple(Awaitable) -> wait(Awaitable, AwaitableTimeout)
    end;
wait_info(InfoId, InfoTimeout, AwaitableTimeout) ->
    wait_info({info, InfoId}, InfoTimeout, AwaitableTimeout).

%% -------------------------------------------------------------------------------------------------
%% SDK functions

-doc #{group => "SDK functions"}.
-spec start_execution(Function :: atom()) -> execution() | no_return().
start_execution(Function) ->
    start_execution(Function, []).

-doc #{group => "SDK functions"}.
-spec start_execution(Function :: atom(), Input :: term()) -> execution() | no_return().
start_execution(Function, Input) ->
    #{execution_module := EM} = ?API_CTX,
    % eqwalizer:ignore
    start_execution(EM, Function, Input, [{execution_id, Function}]).

-doc #{group => "SDK functions"}.
-spec start_execution(
    Function :: atom(),
    Input :: term(),
    Opts :: start_execution_opts()
) -> execution() | no_return().
start_execution(Function, Input, Opts) ->
    #{execution_module := EM} = ?API_CTX,
    Opts1 =
        case
            proplists:is_defined(execution_id, Opts) orelse proplists:is_defined(awaitable_id, Opts)
        of
            true -> Opts;
            false -> [{execution_id, Function} | Opts]
        end,
    % eqwalizer:ignore
    start_execution(EM, Function, Input, Opts1).

-doc #{group => "SDK functions"}.
-spec start_execution(
    Module :: module(),
    Function :: atom(),
    Input :: term(),
    Opts :: start_execution_opts()
) -> execution() | execution_data() | no_return().
start_execution(Module, Function, Input, Opts) ->
    DftId =
        case proplists:is_defined(awaitable_id, Opts) of
            true -> '$_optional';
            false -> temporal_sdk_utils_path:string_path([Module, Function], ":")
        end,
    DefaultOpts = [
        {execution_id, any, DftId},
        {awaitable_id, [unicode, atom, map], '$_optional'},
        {awaitable_event, atom, close},
        {wait, boolean, false}
    ],
    maybe
        {ok, OptsAttr} ?= temporal_sdk_utils_opts:build(DefaultOpts, Opts),
        ok ?= check_opts(execution, OptsAttr),
        {IdxKey, IdxKeyCasted} = temporal_sdk_api_awaitable:gen_idx(
            OptsAttr,
            [execution],
            ?EXECUTION_ID,
            ?AWAIT_COUNTER,
            ?COMMANDS,
            ?API_CTX,
            ?FUNCTION_NAME
        ),
        IdxValue = #{state => cmd, mfa => {Module, Function, Input}},
        do_command(IdxKey, IdxKeyCasted, IdxValue, sdk_command, OptsAttr)
    else
        Err ->
            erlang:error(Err, [Module, Function, Input, Opts])
    end.

-doc #{group => "SDK functions"}.
-spec set_info(InfoValue :: term()) -> info() | no_return().
set_info(InfoValue) -> set_info(InfoValue, []).

-doc #{group => "SDK functions"}.
-spec set_info(
    InfoValue :: term(),
    Opts :: [{info_id, execution_id()} | {awaitable_id, awaitable_id()}]
) -> info() | no_return().
set_info(InfoValue, Opts) ->
    DftId =
        case proplists:is_defined(info_id, Opts) of
            true -> '$_optional';
            false -> #{prefix => true, postfix => true}
        end,
    DefaultOpts = [
        {info_id, any, '$_optional'},
        {awaitable_id, [unicode, atom, map], DftId}
    ],
    case temporal_sdk_utils_opts:build(DefaultOpts, Opts) of
        {ok, OptsAttr} ->
            {IdxKey, IdxKeyCasted} = temporal_sdk_api_awaitable:gen_idx(
                OptsAttr, [info], ?EXECUTION_ID, ?AWAIT_COUNTER, ?COMMANDS, ?API_CTX, ?FUNCTION_NAME
            ),
            do_command(IdxKey, IdxKeyCasted, InfoValue, sdk_command, OptsAttr);
        Err ->
            erlang:error(Err, [InfoValue, Opts])
    end.

-doc #{group => "SDK functions"}.
-spec workflow_info() -> workflow_info() | no_return().
workflow_info() -> call_id(workflow_info).

-doc #{group => "SDK functions"}.
-spec get_workflow_result() -> temporal_sdk:term_to_payloads() | no_return().
get_workflow_result() -> call_id(get_workflow_result).

-doc #{group => "SDK functions"}.
-spec set_workflow_result(WorkflowResult :: temporal_sdk:term_to_payloads()) -> ok.
set_workflow_result(WorkflowResult) -> cast_id({set_workflow_result, WorkflowResult}).

-doc #{group => "SDK functions"}.
-spec stop() -> ok.
stop() -> stop(normal).

-doc #{group => "SDK functions"}.
-spec stop(Reason :: term()) -> ok.
stop(Reason) -> cast_id({stop, Reason}).

-doc #{group => "SDK functions"}.
-spec await_open_before_close(IsEnabled :: boolean()) -> ok.
await_open_before_close(IsEnabled) -> cast_id({await_open_before_close, IsEnabled}).

%% history and index tables commands

-doc #{group => "SDK functions"}.
-spec select_index
    (AwaitableIndexPattern :: awaitable_index_pattern()) -> [awaitable_index()];
    (IndexPatternSpec :: awaitable_index_pattern_match_spec()) -> [awaitable_index()];
    (Continuation :: ets_continuation()) ->
        {[awaitable_index()], Continuation :: ets_continuation()} | '$end_of_table'.
select_index(AwaitableIndexPattern) when
    is_tuple(AwaitableIndexPattern), tuple_size(AwaitableIndexPattern) =:= 2
->
    % eqwalizer:ignore
    ets:select(?INDEX_TABLE, [{AwaitableIndexPattern, [], ['$_']}]);
select_index(IndexPatternSpec) when is_list(IndexPatternSpec) ->
    ets:select(?INDEX_TABLE, IndexPatternSpec);
select_index(Continuation) when is_tuple(Continuation), tuple_size(Continuation) > 4 ->
    % eqwalizer:ignore
    ets:select(Continuation).

-doc #{group => "SDK functions"}.
-spec select_index(
    IndexPatternSpec :: awaitable_index_pattern_match_spec(),
    Limit :: pos_integer()
) ->
    {[awaitable_index()], Continuation :: ets_continuation()} | '$end_of_table'.
select_index(IndexPatternSpec, Limit) when is_integer(Limit) ->
    ets:select(?INDEX_TABLE, IndexPatternSpec, Limit).

-doc #{group => "SDK functions"}.
-spec select_history
    (EventId :: pos_integer()) -> history_event() | noevent;
    (HistoryEventPattern :: history_event_table_pattern()) -> [history_event()];
    (HistoryPatternSpec :: history_event_table_pattern_match_spec()) -> [history_event()];
    (Continuation :: ets_continuation()) ->
        {[history_event()], Continuation :: ets_continuation()} | '$end_of_table'.
select_history(EventId) when is_integer(EventId), EventId > 0 ->
    case ets:select(?HISTORY_TABLE, [{{EventId, '_', '_', '_'}, [], ['$_']}], 1) of
        {[Match], '$end_of_table'} -> Match;
        '$end_of_table' -> noevent
    end;
select_history(HistoryEventPattern) when
    is_tuple(HistoryEventPattern), tuple_size(HistoryEventPattern) =:= 4
->
    % eqwalizer:ignore
    ets:select(?HISTORY_TABLE, [{HistoryEventPattern, [], ['$_']}]);
select_history(HistoryPatternSpec) when is_list(HistoryPatternSpec) ->
    ets:select(?HISTORY_TABLE, HistoryPatternSpec);
select_history(Continuation) when is_tuple(Continuation), tuple_size(Continuation) > 4 ->
    % eqwalizer:ignore
    ets:select(Continuation).

-doc #{group => "SDK functions"}.
-spec select_history(
    HistoryPatternSpec :: history_event_table_pattern_match_spec(),
    Limit :: pos_integer()
) ->
    {[history_event()], Continuation :: ets_continuation()} | '$end_of_table'.
select_history(HistoryPatternSpec, Limit) when is_integer(Limit) ->
    ets:select(?HISTORY_TABLE, HistoryPatternSpec, Limit).

%% -------------------------------------------------------------------------------------------------
%% private

do_command(IdxKey, IdxKeyCasted, IdxValue, Command, Opts) ->
    Index = {IdxKeyCasted, IdxValue},
    C = temporal_sdk_executor:get_commands(),
    temporal_sdk_executor:set_commands([{Index, Command} | C]),
    case Opts of
        #{wait := true} -> wait(IdxKey);
        #{} -> IdxKey
    end.

check_opts(record_marker, Opts) ->
    case Opts of
        #{type := T} when T =:= message; T =:= "message"; T =:= ~"message" ->
            "Marker <message> type is reserved for OTP messages.";
        _ ->
            ok
    end;
check_opts(start_activity, Opts) ->
    case Opts of
        #{task_queue := _, session_execution := true} ->
            "task_queue and session_execution are mutually exclusive.";
        #{session_execution := true, node_execution_fun := _} ->
            "session_execution and node_execution_fun are mutually exclusive.";
        #{direct_execution := true, direct_result := false} ->
            "direct_result implies direct_execution.";
        #{direct_execution := true, eager_execution := false} ->
            "direct_execution implies eager_execution.";
        #{direct_result := true, eager_execution := false} ->
            "direct_result implies eager_execution.";
        #{awaitable_event := E} when
            E =/= cmd, E =/= cancel_request, E =/= result, E =/= schedule, E =/= start, E =/= close
        ->
            "awaitable_event must be one of: cmd, cancel_request, result, schedule, start, close.";
        #{activity_id := _, awaitable_id := _} ->
            "activity_id and awaitable_id are mutually exclusive.";
        _ ->
            ok
    end;
check_opts(execution, Opts) ->
    case Opts of
        #{execution_id := undefined} ->
            "`undefined` <execution_id> is reserved for internal use.";
        _ ->
            ok
    end;
check_opts(respond_query, Opts) ->
    case Opts of
        #{answer := _, error_message := _} ->
            "answer and error_message are mutually exclusive.";
        #{answer := _, failure := _} ->
            "answer and failure are mutually exclusive.";
        Q ->
            case map_size(maps:with([answer, error_message, failure], Q)) of
                0 -> "required one of: answer or error_message / failure.";
                _ -> ok
            end
    end.

fail_cancel_from_data(AwaitableType, AwaitableData, Opts) ->
    Err =
        case temporal_sdk_api_awaitable_index:is_closed(AwaitableType, AwaitableData) of
            true -> " Cannot cancel already closed awaitable.";
            false -> ""
        end,
    erlang:error("Awaitable cancelation using awaitable data not supported." ++ Err, [
        AwaitableType, AwaitableData, Opts
    ]).
