-module(temporal_sdk_utils_logger).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    log_error/5
]).

-include_lib("kernel/include/logger.hrl").

-spec log_error(
    Error, Module :: module(), Function :: atom(), Description :: term(), Data :: term()
) -> Error.
log_error(Error, Module, Function, Description, Data) ->
    ?LOG_ERROR(#{
        reason => Error,
        module => Module,
        function => Function,
        description => Description,
        data => Data
    }),
    Error.
