-define(ROPTS, [{worker_opts, #{namespace => ?NS}}]).
-define(RTOPTS(W___Id), [
    {start_workflow_opts, [{namespace, ?NS}, {workflow_id, W___Id}]},
    {replay_workflow_opts, [{worker_opts, #{namespace => ?NS}}]}
]).
-define(RTOPTSF(W____Id, F___Path),
    ?RTOPTS(W____Id) ++ [{history_file, F___Path}, {history_file_write_modes, [raw, sync]}]
).

-define(assertReplayEqual(Guard, ExecuteFn), begin
    ((fun() ->
        W__Mod = temporal_sdk_utils_path:atom_path([
            ?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, workflow
        ]),
        meck:expect(W__Mod, execute, ExecuteFn),
        W__Id = temporal_sdk_utils_path:string_path([?BASE_DIR, ?MODULE, ?FUNCTION_NAME]),
        ?assertEqual(
            {ok, Guard}, temporal_sdk:replay_task(?CL, ?TQ, W__Mod, W__Mod, ?RTOPTS(W__Id))
        )
    end)())
end).

-define(assertReplayMatch(Guard, ExecuteFn), begin
    ((fun() ->
        W__Mod = temporal_sdk_utils_path:atom_path([
            ?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, workflow
        ]),
        meck:expect(W__Mod, execute, ExecuteFn),
        W__Id = temporal_sdk_utils_path:string_path([?BASE_DIR, ?MODULE, ?FUNCTION_NAME]),
        ?assertMatch(
            {ok, Guard}, temporal_sdk:replay_task(?CL, ?TQ, W__Mod, W__Mod, ?RTOPTS(W__Id))
        )
    end)())
end).

-define(assertReplayEqual(Guard, ExecuteFn, FilePath), begin
    ((fun() ->
        W__Mod = temporal_sdk_utils_path:atom_path([
            ?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, workflow
        ]),
        meck:expect(W__Mod, execute, ExecuteFn),
        F__Path = filename:join([?BASE_DIR | FilePath]) ++ ".json",
        wait__for__file(F__Path),
        case temporal_sdk:replay_file(?CL, W__Mod, F__Path, ?ROPTS) of
            {ok, W__Replay} -> ?assertEqual(Guard, W__Replay);
            Err -> ?assertMatch(Guard, Err)
        end
    end)())
end).

-define(assertReplayMatch(Guard, ExecuteFn, FilePath), begin
    ((fun() ->
        W__Mod = temporal_sdk_utils_path:atom_path([
            ?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, workflow
        ]),
        meck:expect(W__Mod, execute, ExecuteFn),
        F__Path = filename:join([?BASE_DIR | FilePath]) ++ ".json",
        wait__for__file(F__Path),
        case temporal_sdk:replay_file(?CL, W__Mod, F__Path, ?ROPTS) of
            {ok, W__Replay} -> ?assertMatch(Guard, W__Replay);
            Err -> ?assertMatch(Guard, Err)
        end
    end)())
end).

-define(assertReplayEqualF(Guard, ExecuteFn, FilePath), begin
    ((fun() ->
        File__Path = FilePath ++ [?FUNCTION_NAME],
        F__Path = filename:join([?BASE_DIR | File__Path]) ++ ".json",
        case filelib:is_file(F__Path) of
            true ->
                ?assertReplayEqual(Guard, ExecuteFn, File__Path);
            false ->
                W__Mod = temporal_sdk_utils_path:atom_path([
                    ?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, workflow
                ]),
                meck:expect(W__Mod, execute, ExecuteFn),
                D__Path = filename:join([?BASE_DIR | lists:droplast(File__Path)]),
                ok = filelib:ensure_path(D__Path),
                W__Id = temporal_sdk_utils_path:string_path([?BASE_DIR, ?MODULE, ?FUNCTION_NAME]),
                ?assertEqual(
                    {ok, Guard, F__Path},
                    temporal_sdk:replay_task(?CL, ?TQ, W__Mod, W__Mod, ?RTOPTSF(W__Id, F__Path))
                )
        end
    end)())
end).

-define(assertReplayMatchF(Guard, ExecuteFn, FilePath), begin
    ((fun() ->
        File__Path = FilePath ++ [?FUNCTION_NAME],
        F__Path = filename:join([?BASE_DIR | File__Path]) ++ ".json",
        case filelib:is_file(F__Path) of
            true ->
                ?assertReplayMatch(Guard, ExecuteFn, File__Path);
            false ->
                W__Mod = temporal_sdk_utils_path:atom_path([
                    ?MODULE, ?FUNCTION_NAME, ?FUNCTION_ARITY, workflow
                ]),
                meck:expect(W__Mod, execute, ExecuteFn),
                D__Path = filename:join([?BASE_DIR | lists:droplast(File__Path)]),
                ok = filelib:ensure_path(D__Path),
                W__Id = temporal_sdk_utils_path:string_path([?BASE_DIR, ?MODULE, ?FUNCTION_NAME]),
                ?assertMatch(
                    {ok, Guard, F__Path},
                    temporal_sdk:replay_task(?CL, ?TQ, W__Mod, W__Mod, ?RTOPTSF(W__Id, F__Path))
                )
        end
    end)())
end).

-export([wait__for__file/1]).

wait__for__file(Path) ->
    case filelib:is_file(Path) of
        true ->
            case filelib:file_size(Path) > 0 of
                true ->
                    ok;
                false ->
                    timer:sleep(500),
                    wait__for__file(Path)
            end;
        false ->
            timer:sleep(200),
            wait__for__file(Path)
    end.
