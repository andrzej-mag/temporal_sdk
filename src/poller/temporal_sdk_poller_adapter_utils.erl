-module(temporal_sdk_poller_adapter_utils).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    is_task_valid/2,
    validate_temporal_task_name/3
]).

-define(EXECUTE_FUN_ARITY, 2).

-spec is_task_valid(Task :: map(), Required :: [atom()]) -> true | {error, Reason :: term()}.
is_task_valid(Task, Required) when is_map(Task) ->
    case Required -- maps:keys(Task) of
        [] ->
            true;
        Missing ->
            {error, #{reason => "Polled incomplete Temporal task.", missing_keys => Missing}}
    end;
is_task_valid(InvalidTask, _Required) ->
    {error, #{reason => "Polled invalid Temporal task.", invalid_task => InvalidTask}}.

-spec validate_temporal_task_name(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    WorkerOpts :: temporal_sdk_worker:opts(),
    TemporalTaskName :: unicode:chardata()
) -> {ok, module()} | {error, Reason :: term()}.
validate_temporal_task_name(Cluster, WorkerOpts, TemporalTaskName) ->
    #{
        allowed_temporal_names := AllowedTemporalNames,
        allowed_erlang_modules := AllowedErlangModules,
        temporal_name_to_erlang := TemporalNameToErlang
    } = WorkerOpts,
    case
        is_name_allowed(TemporalTaskName, AllowedTemporalNames) orelse
            is_name_allowed(
                temporal_sdk_utils_unicode:characters_to_list1(TemporalTaskName),
                AllowedTemporalNames
            ) orelse
            is_name_allowed(
                temporal_sdk_utils_unicode:characters_to_binary1(TemporalTaskName),
                AllowedTemporalNames
            )
    of
        true ->
            case TemporalNameToErlang(Cluster, TemporalTaskName) of
                {ok, TaskMod} ->
                    case is_name_allowed(TaskMod, AllowedErlangModules) of
                        true ->
                            case is_callback_defined(TaskMod, ?EXECUTE_FUN_ARITY) of
                                true ->
                                    {ok, TaskMod};
                                Err ->
                                    {error,
                                        {Err, #{
                                            cluster => Cluster,
                                            temporal_type_name => TemporalTaskName,
                                            erlang_module_name => TaskMod,
                                            allowed_temporal_names => AllowedTemporalNames,
                                            allowed_erlang_modules => AllowedErlangModules,
                                            temporal_name_to_erlang => TemporalNameToErlang
                                        }}}
                            end;
                        false ->
                            {error,
                                {erlang_module_name_not_allowed, #{
                                    cluster => Cluster,
                                    temporal_type_name => TemporalTaskName,
                                    erlang_module_name => TaskMod,
                                    allowed_temporal_names => AllowedTemporalNames,
                                    allowed_erlang_modules => AllowedErlangModules,
                                    temporal_name_to_erlang => TemporalNameToErlang
                                }}}
                    end;
                Err ->
                    Err
            end;
        false ->
            {error,
                {temporal_task_name_not_allowed, #{
                    cluster => Cluster,
                    temporal_type_name => TemporalTaskName,
                    allowed_temporal_names => AllowedTemporalNames,
                    allowed_erlang_modules => AllowedErlangModules,
                    temporal_name_to_erlang => TemporalNameToErlang
                }}}
    end.

is_name_allowed(_Name, all) -> true;
is_name_allowed(Name, NamesList) -> lists:member(Name, NamesList).

is_callback_defined(Mod, Arity) ->
    case code:ensure_loaded(Mod) of
        {module, Mod} ->
            case erlang:function_exported(Mod, execute, Arity) of
                true -> true;
                false -> undefined_behavior_callback
            end;
        _Err ->
            undefined_behavior_module
    end.
