-define(SETUP(Config), begin
    [
        application:set_env(temporal_sdk, Cluster, ClusterConfig)
     || {Cluster, ClusterConfig} <- Config
    ],
    case application:ensure_all_started(temporal_sdk) of
        {ok, StartedApps} ->
            StartedApps;
        Err ->
            ?debugFmt("~n~nTests execution halted on application start error:~n~p~n", [Err]),
            halt(1)
    end
end).

-define(CLEANUP(StartedApps),
    lists:foreach(fun(A) -> ok = application:stop(A) end, StartedApps)
).
