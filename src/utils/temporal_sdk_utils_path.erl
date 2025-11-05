-module(temporal_sdk_utils_path).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    atom_path/1,
    atom_path/2,
    string_path/1,
    string_path/2
]).

-spec atom_path(Components :: list()) -> atom().
atom_path(Components) when is_list(Components) ->
    atom_path(Components, '/').

-spec atom_path(Components :: list(), Separator :: term()) -> atom().
atom_path(Components, Separator) when is_list(Components) ->
    erlang:list_to_atom(string_path(Components, Separator)).

-spec string_path(Components :: list()) -> string().
string_path(Components) when is_list(Components) ->
    string_path(Components, '/').

-spec string_path(Components :: list(), Separator :: term()) -> string().
string_path(Components, Separator) when is_list(Components) ->
    lists:concat(list_path(Components, Separator)).

-spec list_path(Components :: list(), Separator :: term()) -> [atom() | string()].
list_path(Components, Separator) ->
    % eqwalizer:ignore
    lists:join(Separator, do_to_list(Components)).

-spec do_to_list(Components :: list()) -> [string()].
do_to_list(Components) ->
    [
        case C of
            C when is_atom(C) -> atom_to_list(C);
            C when is_integer(C) -> integer_to_list(C);
            C when is_binary(C) -> temporal_sdk_utils_unicode:characters_to_list1(C);
            C when is_pid(C) -> pid_to_list(C);
            C1 ->
                case io_lib:char_list(C1) of
                    true ->
                        C1;
                    false ->
                        temporal_sdk_utils_unicode:characters_to_list1(io_lib:format("~0tkp", [C1]))
                end
        end
     || C <- Components
    ].
