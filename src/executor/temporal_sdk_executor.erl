-module(temporal_sdk_executor).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    set_executor_dict/1,
    set_executor_dict/8,
    get_executor/0,
    get_execution_id/0,
    get_execution_idx/0,
    get_api_context/0,
    get_api_context_activity/0,
    get_otel_context/0,
    get_history_table/0,
    get_index_table/0,
    get_await_counter/0,
    get_commands/0,
    set_commands/1,
    inc_await_counter/0
]).

-export([
    call/1,
    call_id/1,
    cast/1,
    cast_id/1
]).

-include("temporal_sdk_executor.hrl").

-spec set_executor_dict(ExecutorPid :: pid()) -> term().
set_executor_dict(ExecutorPid) -> put(?PID_KEY, ExecutorPid).

-spec set_executor_dict(
    ExecutorPid :: pid(),
    ExecutionId :: temporal_sdk_workflow:execution_id(),
    ExecutionIdx :: pos_integer(),
    ApiContext :: temporal_sdk_api:context(),
    ApiCtxActivity :: temporal_sdk_api:context(),
    OtelContext :: otel_ctx:t(),
    HistoryTable :: ets:table(),
    IndexTable :: ets:table()
) -> term().
set_executor_dict(
    ExecutorPid,
    ExecutionId,
    ExecutionIdx,
    ApiContext,
    ApiCtxActivity,
    OtelContext,
    HistoryTable,
    IndexTable
) ->
    put(?PID_KEY, ExecutorPid),
    put(?ID_KEY, ExecutionId),
    put(?IDX_KEY, ExecutionIdx),
    put(?API_CTX_KEY, ApiContext),
    put(?API_CTX_ACTIVITY_KEY, ApiCtxActivity),
    put(?OTEL_CTX_ID_KEY, OtelContext),
    put(?HISTORY_TABLE_KEY, HistoryTable),
    put(?INDEX_TABLE_KEY, IndexTable),
    put(?COMMANDS_KEY, []),
    put(?AWAIT_COUNTER_KEY, 0).

-spec get_executor() -> ExecutorPid :: pid() | no_return().
get_executor() -> get_dictkey(?PID_KEY).

-spec get_execution_id() -> ExecutionId :: temporal_sdk_workflow:execution_id() | no_return().
get_execution_id() -> get_dictkey(?ID_KEY).

-spec get_execution_idx() -> ExecutionId :: pos_integer() | no_return().
get_execution_idx() -> get_dictkey(?IDX_KEY).

-spec get_api_context() -> ApiContext :: temporal_sdk_api:context() | no_return().
get_api_context() -> get_dictkey(?API_CTX_KEY).

-spec get_api_context_activity() -> ApiContext :: temporal_sdk_api:context() | no_return().
get_api_context_activity() -> get_dictkey(?API_CTX_ACTIVITY_KEY).

-spec get_otel_context() -> OtelContext :: otel_ctx:t() | no_return().
get_otel_context() -> get_dictkey(?OTEL_CTX_ID_KEY).

-spec get_history_table() -> ets:table() | no_return().
get_history_table() -> get_dictkey(?HISTORY_TABLE_KEY).

-spec get_index_table() -> ets:table() | no_return().
get_index_table() -> get_dictkey(?INDEX_TABLE_KEY).

-spec get_await_counter() -> pos_integer() | no_return().
get_await_counter() -> get_dictkey(?AWAIT_COUNTER_KEY).

-spec get_commands() -> [temporal_sdk_workflow:index_command()].
get_commands() -> get_dictkey(?COMMANDS_KEY).

-spec set_commands(Commands :: [temporal_sdk_workflow:index_command()]) ->
    [temporal_sdk_workflow:index_command()].
set_commands(Commands) -> put(?COMMANDS_KEY, Commands).

-spec inc_await_counter() -> pos_integer().
inc_await_counter() ->
    put(?AWAIT_COUNTER_KEY, get_dictkey(?AWAIT_COUNTER_KEY) + 1).

get_dictkey(DictKey) ->
    case get(DictKey) of
        undefined -> throw({undefined_dictionary_key, DictKey});
        V -> V
    end.

-spec call(Request :: term()) -> Reply :: dynamic() | no_return().
call(Request) ->
    gen_statem:call(get_executor(), {?MSG_API, Request}).

-spec call_id(Request :: term()) -> Reply :: dynamic() | no_return().
call_id(Request) ->
    gen_statem:call(get_executor(), {?MSG_API, get_execution_id(), Request}).

-spec cast(Request :: term()) -> ok.
cast(Request) ->
    gen_statem:cast(get_executor(), {?MSG_API, Request}).

-spec cast_id(Request :: term()) -> ok.
cast_id(Request) ->
    gen_statem:cast(get_executor(), {?MSG_API, get_execution_id(), Request}).
