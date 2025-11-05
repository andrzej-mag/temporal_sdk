-module(temporal_sdk_test_include_asserts_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").
-include("test/include/temporal_sdk_test_asserts.hrl").

-define(MOD, temporal_sdk_test_module).
-define(FUN, temporal_sdk_test_function).

setup_assert_match_retry() ->
    persistent_term:put({?MODULE, ?FUNCTION_NAME, counter}, 0),
    meck:new(?MOD, [non_strict]),
    meck:expect(?MOD, ?FUN, fun(Limit) ->
        C = persistent_term:get({?MODULE, ?FUNCTION_NAME, counter}),
        case C < Limit of
            true ->
                persistent_term:put({?MODULE, ?FUNCTION_NAME, counter}, C + 1),
                error;
            false ->
                ok
        end
    end).

cleanup_assert_match_retry() ->
    meck:unload(?MOD),
    persistent_term:erase({?MODULE, ?FUNCTION_NAME, counter}).

assert_match_retry_0_test() ->
    setup_assert_match_retry(),
    ?assertMatchRetry(ok, ?MOD:?FUN(0)),
    cleanup_assert_match_retry().
assert_match_retry_1_test() ->
    setup_assert_match_retry(),
    ?assertMatchRetry(ok, ?MOD:?FUN(1)),
    cleanup_assert_match_retry().
assert_match_retry_3_test() ->
    setup_assert_match_retry(),
    ?assertMatchRetry(ok, ?MOD:?FUN(3)),
    cleanup_assert_match_retry().
assert_match_retry_error_test() ->
    setup_assert_match_retry(),
    ?assertMatchRetry(error, ?MOD:?FUN(999_999)),
    cleanup_assert_match_retry().

-endif.
