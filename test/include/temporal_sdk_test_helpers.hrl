-define(logError(Reason, Error),
    erlang:error(
        {logError, [
            {module, ?MODULE},
            {line, ?LINE},
            {reason, (Reason)},
            {error, (Error)}
        ]}
    )
).
