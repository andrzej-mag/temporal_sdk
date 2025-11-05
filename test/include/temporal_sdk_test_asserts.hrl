-define(assertCodec(Cluster, Config, Value), begin
    ((fun() ->
        Client = proplists:get_value(
            client, proplists:get_value(Cluster, proplists:get_value(clusters, Config))
        ),
        RequestOpts = maps:get(grpc_opts, Client, #{}),
        {Codec, _, _} = maps:get(codec, RequestOpts, {temporal_sdk_codec_strings, [], []}),
        case Codec of
            temporal_sdk_codec_strings -> ?assert(io_lib:char_list(Value));
            temporal_sdk_codec_strings_copied -> ?assert(io_lib:char_list(Value));
            temporal_sdk_codec_binaries -> ?assert(is_binary(Value));
            temporal_sdk_codec_binaries_copied -> ?assert(is_binary(Value))
        end
    end)())
end).

-define(assertMatchRetry(Guard, Expr), begin
    ((fun() ->
        timer:sleep(100),
        case (Expr) of
            Guard ->
                ok;
            X__V ->
                timer:sleep(500),
                case (Expr) of
                    Guard ->
                        ok;
                    X__V ->
                        timer:sleep(2_000),
                        case (Expr) of
                            Guard ->
                                ok;
                            X__V ->
                                timer:sleep(2_000),
                                ?assertMatch(Guard, Expr)
                        end
                end
        end
    end)())
end).

-define(assertMatchEvent(EventType, AttributesMatch, Events), begin
    ((fun() ->
        Fn = fun(E) ->
            case E of
                (#{event_type := EventType, attributes := {_, AttributesMatch}}) -> true;
                (_) -> false
            end
        end,
        case lists:search(Fn, Events) of
            {value, _} ->
                ok;
            false ->
                io:fwrite(
                    "~nEvent type: ~n~p~n"
                    "with attributes guard: ~n~p~n"
                    "was expected to match following Temporal history events list: ~n~p~n",
                    [EventType, ??AttributesMatch, Events]
                ),
                ?assert(false)
        end
    end)())
end).

-ifdef(INTEGRATION_TEST).
% TODO: replace this with current `temporal_sdk:get_workflow_history/3`
-define(assertGetEvents(RunId), begin
    ((fun() ->
        GetFn = fun() -> temporal_sdk:get_workflow_execution_history(?CL, ?NS, ?WF_ID, RunId) end,
        case GetFn() of
            {ok, #{history := #{events := Events}}} ->
                Events;
            Err ->
                timer:sleep(500),
                case GetFn() of
                    {ok, #{history := #{events := Events}}} ->
                        Events;
                    Err ->
                        timer:sleep(1000),
                        case GetFn() of
                            {ok, #{history := #{events := Events}}} ->
                                Events;
                            Err ->
                                timer:sleep(1000),
                                case GetFn() of
                                    {ok, #{history := #{events := Events}}} ->
                                        Events;
                                    Err ->
                                        ?assertMatch({ok, #{history := #{events := _}}}, Err)
                                end
                        end
                end
        end
    end)())
end).
-endif.
