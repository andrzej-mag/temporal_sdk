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
        workflow_scope := {Scope, PartitionsSize}
    } = ApiContext
) ->
    PartitionId = partition_id(PartitionsSize, Namespace, WorkflowId, RunId),
    ApiContext#{
        workflow_scope := #{
            scope => Scope,
            partitions_size => PartitionsSize,
            partition_id => PartitionId,
            ets_scope_id => ets_scope_id(Scope, PartitionId),
            pg_scope_id => pg_scope_id(Scope, PartitionId)
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

build_ets_ids(#{workflow_scope := #{scope := Scope, partition_id := PartitionId}}, TableId) ->
    History = temporal_sdk_utils_path:atom_path([?MODULE, ets, Scope, PartitionId, TableId, history]),
    Index = temporal_sdk_utils_path:atom_path([?MODULE, ets, Scope, PartitionId, TableId, index]),
    {History, Index}.

ets_scope_id(Scope, PartitionId) ->
    temporal_sdk_utils_path:atom_path([?MODULE, ets, Scope, PartitionId]).

pg_scope_id(Scope, PartitionId) ->
    temporal_sdk_utils_path:atom_path([?MODULE, pg, Scope, PartitionId]).

partition_id(PartitionsSize, Namespace, WorkflowId, RunId) ->
    case erlang:adler32([Namespace, WorkflowId, RunId]) rem PartitionsSize of
        0 -> rand:uniform(PartitionsSize);
        V -> V
    end.
