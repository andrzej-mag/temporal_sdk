-module(temporal_sdk_utils_error_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-import(temporal_sdk_utils_error, [
    normalize_error/1
]).

normalize_error_test() ->
    ?assertEqual(
        {error, {reason, stack}},
        normalize_error({{nocatch, reason}, stack})
    ),
    ?assertEqual(
        {error, reason},
        normalize_error(reason)
    ),
    ?assertEqual(
        {error, "reason"},
        normalize_error("reason")
    ),
    ?assertEqual(
        {error, ["reason1", "reason2"]},
        normalize_error(["reason1", "reason2"])
    ),
    ?assertEqual(
        {error, reason},
        normalize_error({error, reason})
    ),
    ?assertEqual(
        {error, {reason, details}},
        normalize_error({error, reason, details})
    ),
    ?assertEqual(
        {error, {r1, r2, r3}},
        normalize_error({r1, r2, r3})
    ),
    ?assertEqual(
        {error, {error, r1, r2, r3}},
        normalize_error({error, r1, r2, r3})
    ).

-endif.
