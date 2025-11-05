-module(temporal_sdk_utils_error).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    normalize_error/1
]).

-type error() ::
    {error, Reason :: term()} | {error, {Reason :: term(), Details :: term()}} | {error, term()}.
-export_type([error/0]).

-spec normalize_error(Error :: term()) -> error().
normalize_error({error, Reason}) -> {error, Reason};
normalize_error({error, Reason, Details}) -> {error, {Reason, Details}};
normalize_error({{nocatch, Reason}, Stack}) -> {error, {Reason, Stack}};
normalize_error(Error) -> {error, Error}.
