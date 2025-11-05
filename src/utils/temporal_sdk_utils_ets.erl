-module(temporal_sdk_utils_ets).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    compile_match_spec/1,
    run_match_spec/2
]).

-spec compile_match_spec(EtsPattern :: term()) -> {ok, ets:compiled_match_spec()} | error.
compile_match_spec(EtsPattern) ->
    Compiled = ets:match_spec_compile([{{EtsPattern, '$1'}, [], ['$1']}]),
    case ets:is_compiled_ms(Compiled) of
        true -> {ok, Compiled};
        false -> error
    end.

-spec run_match_spec(CompiledPattern :: ets:compiled_match_spec(), Data :: term()) -> boolean().
run_match_spec(CompiledPattern, Data) ->
    case ets:match_spec_run([{Data, true}], CompiledPattern) of
        [true] -> true;
        [] -> false
    end.
