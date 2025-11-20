-module(temporal_sdk_nexus).

% elp:ignore W0012 W0040
-moduledoc """
Temporal nexus task module.

WIP - don't use this yet.
""".

-export([
    await_data/1,
    await_data/2,

    complete/1,
    cancel/1,
    fail/1,

    cancel_requested/0,
    elapsed_time/0,
    elapsed_time/1,
    remaining_time/0,
    remaining_time/1,

    get_data/0,
    set_data/1
]).

-import(temporal_sdk_executor, [
    call/1,
    cast/1
]).

-include("proto.hrl").

-type task() :: ?TEMPORAL_SPEC:'temporal.api.workflowservice.v1.PollNexusTaskQueueResponse'().
-export_type([task/0]).

-type context() ::
    #{
        cluster := temporal_sdk_cluster:cluster_name(),
        executor_pid := pid(),
        otel_ctx := otel_ctx:t(),
        task := task(),
        worker_opts := temporal_sdk_worker:opts(),
        operation := unicode:chardata(),
        started_at := SystemTime :: integer(),
        task_timeout := erlang:timeout()
    }.
-export_type([context/0]).

-type handler_context() ::
    #{
        data := data(),
        cancel_requested := boolean(),
        elapsed_time := non_neg_integer(),
        remaining_time := erlang:timeout()
    }.
-export_type([handler_context/0]).

-type data() :: term().
-export_type([data/0]).

%% -------------------------------------------------------------------------------------------------
%% behaviour

-type complete_action() :: {complete, Result :: temporal_sdk:term_to_payloads()}.
-export_type([complete_action/0]).

-type cancel_action() :: {cancel, CanceledDetails :: temporal_sdk:term_to_payloads()}.
-export_type([cancel_action/0]).

-type fail_action() ::
    {fail, {
        Source :: temporal_sdk:serializable(),
        Message :: temporal_sdk:serializable(),
        Stacktrace :: temporal_sdk:serializable()
    }}.
-export_type([fail_action/0]).

-type terminate_action() :: cancel_action() | complete_action() | fail_action().
-export_type([terminate_action/0]).

-type data_action() :: {data, NewData :: data()}.
-export_type([data_action/0]).

-callback execute(Context :: context(), RequestPayload :: temporal_sdk:term_from_payload()) ->
    ResponsePayload :: temporal_sdk:term_to_payload().

-callback handle_terminate(HandlerContext :: handler_context()) ->
    any().

-callback handle_cancel(HandlerContext :: handler_context()) ->
    terminate_action() | ignore.

-callback handle_message(HandlerContext :: handler_context(), Message :: term()) ->
    terminate_action() | data_action() | ignore.

-optional_callbacks([
    handle_cancel/1,
    handle_message/2
]).

%% -------------------------------------------------------------------------------------------------
%% Temporal commands

-spec await_data(EtsPattern :: term()) ->
    {ok, data()} | timeout | invalid_pattern | no_return().
await_data(EtsPattern) ->
    case remaining_time(millisecond) of
        infinity -> await_data(EtsPattern, infinity);
        T -> await_data(EtsPattern, T)
    end.

-spec await_data(EtsPattern :: term(), Timeout :: erlang:timeout()) ->
    {ok, data()} | timeout | invalid_pattern | no_return().
await_data(EtsPattern, Timeout) ->
    case temporal_sdk_utils_ets:compile_match_spec(EtsPattern) of
        {ok, Compiled} -> call({await_data, Compiled, Timeout});
        error -> invalid_pattern
    end.

-spec cancel(CanceledDetails :: temporal_sdk:term_to_payloads()) -> no_return().
cancel(CanceledDetails) ->
    case cancel_requested() of
        true ->
            call({cancel, CanceledDetails});
        false ->
            erlang:error(
                "Unable to cancel nexus operation without nexus operation being request canceled first.",
                [CanceledDetails]
            )
    end.

-spec complete(Result :: temporal_sdk:term_to_payloads()) -> no_return().
complete(Result) ->
    call({complete, Result}).

-spec fail(
    ApplicationFailure ::
        temporal_sdk:application_failure()
        | temporal_sdk:user_application_failure()
) -> no_return().
fail(ApplicationFailure) -> call({fail, ApplicationFailure}).

-spec cancel_requested() -> boolean() | no_return().
cancel_requested() ->
    call({cancel_requested}).

-spec elapsed_time() -> NativeTime :: non_neg_integer() | no_return().
elapsed_time() ->
    call({elapsed_time}).

-spec elapsed_time(Unit :: erlang:time_unit()) -> non_neg_integer() | no_return().
elapsed_time(Unit) ->
    erlang:convert_time_unit(elapsed_time(), native, Unit).

-spec remaining_time() -> NativeTime :: non_neg_integer() | infinity | no_return().
remaining_time() ->
    call({remaining_time}).

-spec remaining_time(Unit :: erlang:time_unit()) -> non_neg_integer() | infinity | no_return().
remaining_time(Unit) ->
    case remaining_time() of
        infinity -> infinity;
        T -> erlang:convert_time_unit(T, native, Unit)
    end.

-spec get_data() -> Data :: data() | no_return().
get_data() ->
    call({get_data}).

-spec set_data(TaskData :: term()) -> ok.
set_data(TaskData) ->
    cast({set_data, TaskData}).
