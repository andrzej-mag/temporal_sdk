-module(temporal_sdk_scope).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    init_ctx/1,
    get_members/1,
    start/1,
    build_ets_ids/2,
    ets_scope_id/2,
    pg_scope_id/2
]).

-spec init_ctx(temporal_sdk_api:context()) -> temporal_sdk_api:context().
init_ctx(
    #{
        worker_opts := #{namespace := Namespace},
        task_opts := #{workflow_id := WorkflowId, run_id := RunId},
        workflow_scope := {Scope, ShardSize}
    } = ApiContext
) ->
    ShardId = shard_id(ShardSize, Namespace, WorkflowId, RunId),
    ApiContext#{
        workflow_scope := #{
            scope => Scope,
            shard_size => ShardSize,
            shard_id => ShardId,
            ets_scope_id => ets_scope_id(Scope, ShardId),
            pg_scope_id => pg_scope_id(Scope, ShardId)
        }
    }.

-spec get_members(ApiContext :: temporal_sdk_api:context()) -> ScopeMembers :: [pid()].
get_members(#{
    enable_single_distributed_workflow_execution := EnableSingleDistWorkflowExecution,
    worker_opts := #{namespace := Namespace},
    task_opts := #{workflow_id := WorkflowId},
    workflow_scope := #{pg_scope_id := PgScopeId}
}) ->
    case EnableSingleDistWorkflowExecution of
        true -> pg:get_members(PgScopeId, {Namespace, WorkflowId});
        false -> pg:get_local_members(PgScopeId, {Namespace, WorkflowId})
    end.

-spec start(ApiContext :: temporal_sdk_api:context()) -> ok.
start(#{
    worker_opts := #{namespace := Namespace},
    task_opts := #{workflow_id := WorkflowId},
    workflow_scope := #{ets_scope_id := EtsScopeId, pg_scope_id := PgScopeId}
}) ->
    temporal_sdk_utils_recycled_int:new(EtsScopeId),
    pg:join(PgScopeId, {Namespace, WorkflowId}, self()).

build_ets_ids(#{workflow_scope := #{scope := Scope, shard_id := ShardId}}, TableId) ->
    History = temporal_sdk_utils_path:atom_path([?MODULE, ets, Scope, ShardId, TableId, history]),
    Index = temporal_sdk_utils_path:atom_path([?MODULE, ets, Scope, ShardId, TableId, index]),
    {History, Index}.

ets_scope_id(Scope, ShardId) ->
    temporal_sdk_utils_path:atom_path([?MODULE, ets, Scope, ShardId]).

pg_scope_id(Scope, ShardId) ->
    temporal_sdk_utils_path:atom_path([?MODULE, pg, Scope, ShardId]).

shard_id(ShardSize, Namespace, WorkflowId, RunId) ->
    case erlang:adler32([Namespace, WorkflowId, RunId]) rem ShardSize of
        0 -> rand:uniform(ShardSize);
        V -> V
    end.
