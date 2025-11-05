%% Example shell command to run tests with custom Temporal cluster endpoints:
%% TEMPORAL_SDK_TEST_ENDPOINT="{{127, 0, 0, 1}, 7233}." \
%% TEMPORAL_SDK_TEST_ENDPOINT_LB_FAILED="{{127, 0, 0, 1}, 7232}." \
%% TEMPORAL_SDK_TEST_ENDPOINT_LB="{{127, 0, 0, 1}, 7234}." \
%% rebar3 eunit

% -define(ENDPOINT_OPTS, #{size => 5, conn_opts => #{protocols => [http2]}}).
-define(ENDPOINT_OPTS, []).

-define(ENDPOINT,
    ?ENV_TO_TERM("TEMPORAL_SDK_TEST_ENDPOINT", {{127, 0, 0, 1}, 7233, ?ENDPOINT_OPTS})
).
-define(ENDPOINT_LB_FAILED,
    ?ENV_TO_TERM("TEMPORAL_SDK_TEST_ENDPOINT_LB_FAILED", {{127, 0, 0, 1}, 7232, ?ENDPOINT_OPTS})
).
-define(ENDPOINT_LB,
    ?ENV_TO_TERM("TEMPORAL_SDK_TEST_ENDPOINT_LB", {{127, 0, 0, 1}, 7234, ?ENDPOINT_OPTS})
).

-define(ENDPOINTS, [
    [?ENDPOINT],
    [?ENDPOINT, ?ENDPOINT_LB_FAILED],
    [?ENDPOINT, ?ENDPOINT_LB_FAILED, ?ENDPOINT_LB]
]).

-define(ENV_TO_TERM(Env, Default),
    case os:getenv(Env) of
        false ->
            Default;
        E ->
            {ok, Tokens, 1} = erl_scan:string(E),
            {ok, Term} = erl_parse:parse_term(Tokens),
            Term
    end
).
