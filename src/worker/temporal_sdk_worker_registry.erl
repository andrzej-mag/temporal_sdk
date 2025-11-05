-module(temporal_sdk_worker_registry).
-behaviour(gen_server).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    count_names/2,
    registered_names/1,
    registered_names/2,
    register_name/2,
    send/2,
    unregister_name/1,
    whereis_name/1
]).
-export([
    start_link/2
]).
-export([
    init/1,
    handle_call/3,
    handle_info/2,
    handle_cast/2
]).

%% -------------------------------------------------------------------------------------------------
%% public

-spec count_names(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: temporal_sdk_worker:worker_type()
) -> non_neg_integer() | temporal_sdk_worker:invalid_error().
count_names(Cluster, WorkerType) ->
    case do_call(Cluster, WorkerType, table) of
        {ok, Table} -> ets_info_size(Table);
        Err -> Err
    end.

-spec ets_info_size(Table :: ets:table()) -> non_neg_integer() | {error, invalid_worker}.
ets_info_size(Table) ->
    case ets:info(Table, size) of
        S when is_integer(S) -> S;
        _ -> {error, invalid_worker}
    end.

-spec registered_names(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: temporal_sdk_worker:worker_type()
) -> [temporal_sdk_worker:worker_id()] | temporal_sdk_worker:invalid_error().
registered_names(Cluster, WorkerType) ->
    registered_names({Cluster, WorkerType}).

-spec registered_names(
    {
        Cluster :: temporal_sdk_cluster:cluster_name(),
        WorkerType :: temporal_sdk_worker:worker_type()
    }
) -> [temporal_sdk_worker:worker_id()] | temporal_sdk_worker:invalid_error().
registered_names({Cluster, WorkerType}) ->
    case do_call(Cluster, WorkerType, table) of
        {ok, Table} -> ets_select_names(Table);
        Err -> Err
    end.

-spec ets_select_names(Table :: ets:table()) -> list() | {error, invalid_worker}.
ets_select_names(Table) ->
    case ets:select(Table, [{{'$1', '_', '_'}, [], ['$1']}]) of
        S when is_list(S) -> S
    end.

-spec register_name(
    {
        Cluster :: temporal_sdk_cluster:cluster_name(),
        WorkerType :: temporal_sdk_worker:worker_type(),
        WorkerId :: temporal_sdk_worker:worker_id()
    },
    Pid :: pid()
) -> yes | no.
register_name({Cluster, WorkerType, WorkerId}, Pid) ->
    case do_call(Cluster, WorkerType, {register, WorkerId, Pid}) of
        {ok, R} -> R;
        _ -> no
    end.

-spec send(
    {
        Cluster :: temporal_sdk_cluster:cluster_name(),
        WorkerType :: temporal_sdk_worker:worker_type(),
        WorkerId :: temporal_sdk_worker:worker_id()
    },
    Msg :: term()
) -> pid().
send({Cluster, WorkerType, WorkerId} = Name, Msg) ->
    case whereis_name({Cluster, WorkerType, WorkerId}) of
        undefined ->
            exit({badarg, {Name, Msg}});
        Pid ->
            Pid ! Msg,
            Pid
    end.

-spec unregister_name(
    {
        Cluster :: temporal_sdk_cluster:cluster_name(),
        WorkerType :: temporal_sdk_worker:worker_type(),
        WorkerId :: temporal_sdk_worker:worker_id()
    }
) -> ok | temporal_sdk_worker:invalid_error().
unregister_name({Cluster, WorkerType, WorkerId}) ->
    case do_call(Cluster, WorkerType, {unregister, WorkerId}) of
        {ok, _} -> ok;
        Err -> Err
    end.

-spec whereis_name(
    {
        Cluster :: temporal_sdk_cluster:cluster_name(),
        WorkerType :: temporal_sdk_worker:worker_type(),
        WorkerId :: temporal_sdk_worker:worker_id()
    }
) -> pid() | undefined.
whereis_name({Cluster, WorkerType, WorkerId}) ->
    case do_call(Cluster, WorkerType, {whereis, WorkerId}) of
        {ok, undefined} -> undefined;
        {ok, Pid} -> Pid;
        _ -> undefined
    end.

%% -------------------------------------------------------------------------------------------------
%% gen_server

-spec start_link(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: temporal_sdk_worker:worker_type()
) -> gen_server:start_ret().
start_link(Cluster, WorkerType) ->
    gen_server:start_link(
        {local, local_name(Cluster, WorkerType)}, ?MODULE, [Cluster, WorkerType], []
    ).

init([Cluster, WorkerType]) ->
    process_flag(trap_exit, true),
    {ok, ets:new(local_name(Cluster, WorkerType), [])}.

handle_call({register, Name, Pid}, _From, Table) ->
    case ets:member(Table, Name) of
        false ->
            ets:insert(Table, {Name, Pid, monitor(process, Pid)}),
            {reply, yes, Table};
        true ->
            {reply, no, Table}
    end;
handle_call({unregister, Name}, _From, Table) ->
    case ets:lookup_element(Table, Name, 3, undefined) of
        Ref when is_reference(Ref) ->
            demonitor(Ref, [flush]),
            ets:delete(Table, Name);
        _ ->
            ok
    end,
    {reply, ok, Table};
handle_call({whereis, Name}, _From, Table) ->
    {reply, ets:lookup_element(Table, Name, 2, undefined), Table};
handle_call(table, _From, Table) ->
    {reply, Table, Table}.

handle_info({'DOWN', Ref, process, Pid, _Reason}, Table) ->
    case ets:select_delete(Table, [{{'_', Pid, Ref}, [], [true]}]) of
        1 -> {noreply, Table};
        _ -> {stop, invalid_registry_state, Table}
    end;
handle_info(_Request, State) ->
    {stop, invalid_request, State}.

handle_cast(_Request, State) ->
    {stop, invalid_request, State}.

%% -------------------------------------------------------------------------------------------------
%% private

-spec do_call(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerType :: temporal_sdk_worker:worker_type(),
    Request :: term()
) -> {ok, dynamic()} | {error, invalid_cluster} | {error, invalid_worker}.
do_call(Cluster, WorkerType, Request) ->
    case temporal_sdk_cluster:is_alive(Cluster) of
        true ->
            try
                {ok, gen_server:call(local_name(Cluster, WorkerType), Request)}
            catch
                exit:{noproc, _} -> {error, invalid_worker}
            end;
        Err ->
            Err
    end.

local_name(Cluster, WorkerType) ->
    temporal_sdk_utils_path:atom_path([?MODULE, Cluster, WorkerType]).
