-module(temporal_sdk_utils_path_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-import(temporal_sdk_utils_path, [
    atom_path/1,
    atom_path/2,
    string_path/1,
    string_path/2
]).

atom_path_1_test() ->
    ?assertEqual('a', atom_path([a])),
    ?assertEqual('a/b', atom_path([a, b])),
    ?assertEqual('a/b/c', atom_path([a, b, c])),
    ?assertEqual('a/b/c', atom_path([a, 'b/c'])),
    ?assertEqual('a/b/c/d', atom_path([a, 'b/c', d])),
    ?assertEqual('a/b/c/d/e', atom_path([a, "b/c", d, "e"])),
    ?assertEqual('a/b/c/d/e/123', atom_path([a, "b/c", d, "e", 123])),
    ?assertEqual('a/b/c/{d}/e/123', atom_path([a, "b/c", {d}, "e", 123])).

atom_path_2_test() ->
    ?assertEqual('a', atom_path([a], '-')),
    ?assertEqual('a', atom_path([a], "-")),
    ?assertEqual('a-b', atom_path([a, b], '-')),
    ?assertEqual('a-b', atom_path([a, b], "-")).

string_path_1_test() ->
    ?assertEqual("a", string_path([a])),
    ?assertEqual("a/b", string_path([a, b])),
    ?assertEqual("a/b/c", string_path([a, b, c])),
    ?assertEqual("a/b/c", string_path([a, 'b/c'])),
    ?assertEqual("a/b/c/d", string_path([a, 'b/c', d])),
    ?assertEqual("a/b/c/d/e", string_path([a, "b/c", d, "e"])),
    ?assertEqual("a/b/c/d/e/123", string_path([a, "b/c", d, "e", 123])),
    ?assertEqual("a/b/c/d/e/123/bin", string_path([a, "b/c", d, "e", 123, ~"bin"])),
    ?assertEqual("a/b/c/d/e/{f}/123/bin", string_path([a, "b/c", d, "e", {f}, 123, ~"bin"])).

string_path_2_test() ->
    ?assertEqual("a", string_path([a], '-')),
    ?assertEqual("a", string_path([a], "-")),
    ?assertEqual("a-b", string_path([a, b], '-')),
    ?assertEqual("a-b", string_path([a, b], "-")).

-endif.
