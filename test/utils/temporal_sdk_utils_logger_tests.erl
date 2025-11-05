-module(temporal_sdk_utils_logger_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-import(temporal_sdk_utils_logger, [
    log_error/5
]).

log_error_test() ->
    ?assertEqual(
        {test_error, test_reason},
        log_error(
            {test_error, test_reason}, ?MODULE, ?FUNCTION_NAME, "Test description.", "Test data."
        )
    ).

-endif.
