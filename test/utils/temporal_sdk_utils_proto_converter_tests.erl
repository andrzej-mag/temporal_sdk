-module(temporal_sdk_utils_proto_converter_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-import(temporal_sdk_utils_proto_converter, [
    convert_paths/7,
    convert_payload/4
]).

-define(CL, cluster).
-define(RI_REQ, #{type => request}).
-define(RI_RSP, #{type => response}).

-define(META_ERL, #{<<"encoding">> => <<"binary/erlang">>}).
-define(META_JSON, #{<<"encoding">> => <<"json/plain">>}).
-define(META_BIN, #{<<"encoding">> => <<"binary/plain">>}).

-define(C_ERL, [
    temporal_sdk_codec_payload_erl
]).

-define(C_JSON, [
    temporal_sdk_codec_payload_json
]).

-define(C_JSON_ERL, [
    temporal_sdk_codec_payload_json,
    temporal_sdk_codec_payload_erl
]).

-define(C_BIN_JSON_ERL, [
    temporal_sdk_codec_payload_binary,
    temporal_sdk_codec_payload_json,
    temporal_sdk_codec_payload_erl
]).

-define(DATA, #{key1 => #{key2 => [atom, "string", <<"binary">>, 123.456]}}).

-define(P, #{data => ?DATA}).
-define(P_ERL, #{data => erlang:term_to_binary(?DATA), metadata => ?META_ERL}).
-define(CP_ERL, #{data => ?DATA, metadata => ?META_ERL}).
-define(P_JSON, #{data => unicode:characters_to_binary(json:encode(?DATA)), metadata => ?META_JSON}).
-define(CP_JSON, #{
    data => json:decode(unicode:characters_to_binary(json:encode(?DATA))), metadata => ?META_JSON
}).

-define(PNAME, 'temporal.api.common.v1.Payload').

%% -------------------------------------------------------------------------------------------------
%% convert_paths/7: [] path

convert_nopath_nomsg_req_nocc_test() ->
    P = [],
    M = #{},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_nopath_nomsg_req_unused_test() ->
    P = [],
    M = #{},
    R = ?RI_REQ,
    CC = [unused],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_nopath_nomsg_rsp_nocc_test() ->
    P = [],
    M = #{},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_nopath_nomsg_rsp_unused_test() ->
    P = [],
    M = #{},
    R = ?RI_RSP,
    CC = [unused],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_nopath_msg1_req_nocc_test() ->
    P = [],
    M = #{k => v},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_nopath_msg1_rsp_nocc_test() ->
    P = [],
    M = #{k => v},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_nopath_msg1_req_unused_test() ->
    P = [],
    M = #{k => v},
    R = ?RI_REQ,
    CC = [unused],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_nopath_msg1_rsp_unused_test() ->
    P = [],
    M = #{k => v},
    R = ?RI_RSP,
    CC = [unused],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

%% -------------------------------------------------------------------------------------------------
%% convert_paths/7: optional path

convert_optional_nomsg_req_nocc_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional_nomsg_rsp_nocc_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional_nomsg_req_unused_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{},
    R = ?RI_REQ,
    CC = [unused],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional_nomsg_rsp_unused_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{},
    R = ?RI_RSP,
    CC = [unused],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional_msg1_req_nocc_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{k => v},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional_msg1_rsp_nocc_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{k => v},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional_msg1_req_unused_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{k => v},
    R = ?RI_REQ,
    CC = [unused],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional_msg1_rsp_unused_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{k => v},
    R = ?RI_RSP,
    CC = [unused],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional_msg2_req_nocc_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{pk => ?P},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, #{pk => ?P_ERL}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => ?P_JSON}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => ?P_JSON}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{pk => ?P_JSON}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional_msg2_rsp_nocc_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{pk => ?P_ERL},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, #{pk => ?CP_ERL}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertMatch({error, _}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => ?CP_ERL}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{pk => ?CP_ERL}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional_msg3_req_nocc_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{pk => ?P, k => v},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, #{pk => ?P_ERL, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => ?P_JSON, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => ?P_JSON, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual(
        {ok, #{pk => ?P_JSON, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional_msg3_rsp_nocc_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{pk => ?P_ERL, k => v},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, #{pk => ?CP_ERL, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertMatch({error, _}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => ?CP_ERL, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual(
        {ok, #{pk => ?CP_ERL, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional_msg3_req_cc1_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{pk => ?P, k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_erl], [mn]}],
    ?assertEqual({ok, #{pk => ?P_ERL, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => ?P_ERL, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => ?P_ERL, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{pk => ?P_ERL, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional_msg3_req_cc2_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{pk => ?P, k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_json], [mn]}],
    ?assertEqual({ok, #{pk => ?P_JSON, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => ?P_JSON, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => ?P_JSON, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual(
        {ok, #{pk => ?P_JSON, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional_msg3_req_cc3_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{pk => ?P, k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_json], [mn]}, {[temporal_sdk_codec_payload_erl], [nokey]}],
    ?assertEqual({ok, #{pk => ?P_JSON, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => ?P_JSON, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => ?P_JSON, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual(
        {ok, #{pk => ?P_JSON, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional_msg3_req_cc4_test() ->
    P = [{pk, {optional, ?PNAME}}],
    M = #{pk => ?P, k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_json], [nokey]}, {[temporal_sdk_codec_payload_erl], [mn]}],
    ?assertEqual({ok, #{pk => ?P_ERL, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => ?P_ERL, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => ?P_ERL, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{pk => ?P_ERL, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

%% -------------------------------------------------------------------------------------------------
%% convert_paths/7: repeated path

convert_repeated_nomsg_req_nocc_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_repeated_nomsg_rsp_nocc_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_repeated_nomsg_req_unused_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{},
    R = ?RI_REQ,
    CC = [unused],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_repeated_nomsg_rsp_unused_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{},
    R = ?RI_RSP,
    CC = [unused],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_repeated_msg1_req_nocc_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{k => v},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_repeated_msg1_rsp_nocc_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{k => v},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_repeated_msg1_req_unused_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{k => v},
    R = ?RI_REQ,
    CC = [unused],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_repeated_msg1_rsp_unused_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{k => v},
    R = ?RI_RSP,
    CC = [unused],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_repeated_msg2_req_nocc_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{pk => [?P]},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, #{pk => [?P_ERL]}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => [?P_JSON]}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => [?P_JSON]}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{pk => [?P_JSON]}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_repeated_msg2_rsp_nocc_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{pk => [?P_ERL]},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, #{pk => [?CP_ERL]}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertMatch({error, _}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => [?CP_ERL]}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{pk => [?CP_ERL]}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_repeated_msg3_req_nocc_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{pk => [?P], k => v},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, #{pk => [?P_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => [?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => [?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual(
        {ok, #{pk => [?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_repeated_msg3_rsp_nocc_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{pk => [?P_ERL], k => v},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, #{pk => [?CP_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertMatch({error, _}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => [?CP_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual(
        {ok, #{pk => [?CP_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_repeated_msg3_req_cc1_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{pk => [?P], k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_erl], [mn]}],
    ?assertEqual({ok, #{pk => [?P_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => [?P_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => [?P_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual(
        {ok, #{pk => [?P_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_repeated_msg3_req_cc2_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{pk => [?P], k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_json], [mn]}],
    ?assertEqual({ok, #{pk => [?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => [?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => [?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual(
        {ok, #{pk => [?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_repeated_msg3_req_cc3_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{pk => [?P], k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_json], [mn]}, {[temporal_sdk_codec_payload_erl], [nokey]}],
    ?assertEqual({ok, #{pk => [?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => [?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => [?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual(
        {ok, #{pk => [?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_repeated_msg3_req_cc4_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{pk => [?P], k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_json], [nokey]}, {[temporal_sdk_codec_payload_erl], [mn]}],
    ?assertEqual({ok, #{pk => [?P_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => [?P_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => [?P_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual(
        {ok, #{pk => [?P_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_repeated_msg4_req_cc3_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{pk => [?P, ?P], k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_json], [mn]}, {[temporal_sdk_codec_payload_erl], [nokey]}],
    ?assertEqual(
        {ok, #{pk => [?P_JSON, ?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => [?P_JSON, ?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{pk => [?P_JSON, ?P_JSON], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => [?P_JSON, ?P_JSON], k => v}},
        convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_repeated_msg4_req_cc4_test() ->
    P = [{pk, {repeated, ?PNAME}}],
    M = #{pk => [?P, ?P], k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_json], [nokey]}, {[temporal_sdk_codec_payload_erl], [mn]}],
    ?assertEqual(
        {ok, #{pk => [?P_ERL, ?P_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => [?P_ERL, ?P_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{pk => [?P_ERL, ?P_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => [?P_ERL, ?P_ERL], k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

%% -------------------------------------------------------------------------------------------------
%% convert_paths/7: map_string path

convert_map_string_nomsg_req_nocc_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_map_string_nomsg_rsp_nocc_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_map_string_nomsg_req_unused_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{},
    R = ?RI_REQ,
    CC = [unused],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_map_string_nomsg_rsp_unused_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{},
    R = ?RI_RSP,
    CC = [unused],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_map_string_msg1_req_nocc_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{k => v},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_map_string_msg1_rsp_nocc_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{k => v},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_map_string_msg1_req_unused_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{k => v},
    R = ?RI_REQ,
    CC = [unused],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_map_string_msg1_rsp_unused_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{k => v},
    R = ?RI_RSP,
    CC = [unused],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_map_string_msg2_req_nocc_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{pk => #{x => ?P}},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, #{pk => #{x => ?P_ERL}}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => #{x => ?P_JSON}}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => #{x => ?P_JSON}}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON}}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_map_string_msg2_rsp_nocc_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{pk => #{x => ?P_ERL}},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, #{pk => #{x => ?CP_ERL}}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertMatch({error, _}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{pk => #{x => ?CP_ERL}}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual(
        {ok, #{pk => #{x => ?CP_ERL}}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_map_string_msg3_req_nocc_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{pk => #{x => ?P}, k => v},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, #{pk => #{x => ?P_ERL}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_map_string_msg3_rsp_nocc_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{pk => #{x => ?P_ERL}, k => v},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, #{pk => #{x => ?CP_ERL}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertMatch({error, _}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual(
        {ok, #{pk => #{x => ?CP_ERL}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?CP_ERL}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_map_string_msg3_req_cc1_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{pk => #{x => ?P}, k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_erl], [mn]}],
    ?assertEqual({ok, #{pk => #{x => ?P_ERL}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => #{x => ?P_ERL}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_ERL}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_ERL}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_map_string_msg3_req_cc2_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{pk => #{x => ?P}, k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_json], [mn]}],
    ?assertEqual({ok, #{pk => #{x => ?P_JSON}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_map_string_msg3_req_cc3_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{pk => #{x => ?P}, k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_json], [mn]}, {[temporal_sdk_codec_payload_erl], [nokey]}],
    ?assertEqual({ok, #{pk => #{x => ?P_JSON}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_map_string_msg3_req_cc4_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{pk => #{x => ?P}, k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_json], [nokey]}, {[temporal_sdk_codec_payload_erl], [mn]}],
    ?assertEqual({ok, #{pk => #{x => ?P_ERL}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{pk => #{x => ?P_ERL}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_ERL}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_ERL}, k => v}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_map_string_msg4_req_cc3_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{pk => #{x => ?P, y => ?P}, k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_json], [mn]}, {[temporal_sdk_codec_payload_erl], [nokey]}],
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON, y => ?P_JSON}, k => v}},
        convert_paths(P, mn, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON, y => ?P_JSON}, k => v}},
        convert_paths(P, mn, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON, y => ?P_JSON}, k => v}},
        convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_JSON, y => ?P_JSON}, k => v}},
        convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_map_string_msg4_req_cc4_test() ->
    P = [{pk, {map_string, ?PNAME}}],
    M = #{pk => #{x => ?P, y => ?P}, k => v},
    R = ?RI_REQ,
    CC = [{[temporal_sdk_codec_payload_json], [nokey]}, {[temporal_sdk_codec_payload_erl], [mn]}],
    ?assertEqual(
        {ok, #{pk => #{x => ?P_ERL, y => ?P_ERL}, k => v}},
        convert_paths(P, mn, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_ERL, y => ?P_ERL}, k => v}},
        convert_paths(P, mn, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_ERL, y => ?P_ERL}, k => v}},
        convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{pk => #{x => ?P_ERL, y => ?P_ERL}, k => v}},
        convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

%% -------------------------------------------------------------------------------------------------
%% convert_paths/7: {RootKey, Key} optional path

convert_optional1_nomsg_req_nocc_test() ->
    P = [{{rk, pk}, {optional, ?PNAME}}],
    M = #{},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional1_nomsg_rsp_nocc_test() ->
    P = [{{rk, pk}, {optional, ?PNAME}}],
    M = #{},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional1_nomsg_req_unused_test() ->
    P = [{{rk, pk}, {optional, ?PNAME}}],
    M = #{},
    R = ?RI_REQ,
    CC = [unused],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional1_nomsg_rsp_unused_test() ->
    P = [{{rk, pk}, {optional, ?PNAME}}],
    M = #{},
    R = ?RI_RSP,
    CC = [unused],
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, #{}}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional1_msg1_req_nocc_test() ->
    P = [{{rk, pk}, {optional, ?PNAME}}],
    M = #{k => v},
    R = ?RI_REQ,
    CC = [],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional1_msg1_rsp_nocc_test() ->
    P = [{{rk, pk}, {optional, ?PNAME}}],
    M = #{k => v},
    R = ?RI_RSP,
    CC = [],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional1_msg1_req_unused_test() ->
    P = [{{rk, pk}, {optional, ?PNAME}}],
    M = #{k => v},
    R = ?RI_REQ,
    CC = [unused],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional1_msg1_rsp_unused_test() ->
    P = [{{rk, pk}, {optional, ?PNAME}}],
    M = #{k => v},
    R = ?RI_RSP,
    CC = [unused],
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_JSON_ERL)),
    ?assertEqual({ok, M}, convert_paths(P, mn, M, c, R, CC, ?C_BIN_JSON_ERL)).

convert_optional1_msg2_req_nocc_test() ->
    P = [
        {
            {attributes, schedule_activity_task_command_attributes},
            {optional, 'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'}
        }
    ],
    M = #{
        attributes => {schedule_activity_task_command_attributes, #{input => #{payloads => [?P]}}}
    },
    R = ?RI_REQ,
    CC = [],
    MN = 'temporal.api.command.v1.Command',
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{input => #{payloads => [?P_ERL]}}}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{input => #{payloads => [?P_JSON]}}}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{input => #{payloads => [?P_JSON]}}}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{input => #{payloads => [?P_JSON]}}}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg2_rsp_nocc_test() ->
    P = [
        {
            {attributes, workflow_execution_started_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'}
        }
    ],
    M = #{
        attributes =>
            {workflow_execution_started_event_attributes, #{input => #{payloads => [?P_ERL]}}}
    },
    R = ?RI_RSP,
    CC = [],
    MN = 'temporal.api.history.v1.HistoryEvent',
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{input => #{payloads => [?CP_ERL]}}}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertMatch({error, _}, convert_paths(P, MN, M, c, R, CC, ?C_JSON)),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{input => #{payloads => [?CP_ERL]}}}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{input => #{payloads => [?CP_ERL]}}}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_req_nocc_test() ->
    P = [
        {
            {attributes, schedule_activity_task_command_attributes},
            {optional, 'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'}
        }
    ],
    M = #{
        attributes =>
            {schedule_activity_task_command_attributes, #{
                input => #{payloads => [?P]}, activity_id => "ID"
            }}
    },
    R = ?RI_REQ,
    CC = [],
    MN = 'temporal.api.command.v1.Command',
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_rsp_nocc_test() ->
    P = [
        {
            {attributes, workflow_execution_started_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'}
        }
    ],
    M = #{
        attributes =>
            {workflow_execution_started_event_attributes, #{
                input => #{payloads => [?P_ERL]}, activity_id => "ID"
            }}
    },
    R = ?RI_RSP,
    CC = [],
    MN = 'temporal.api.history.v1.HistoryEvent',
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertMatch({error, _}, convert_paths(P, MN, M, c, R, CC, ?C_JSON)),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_req_cc1_test() ->
    P = [
        {
            {attributes, schedule_activity_task_command_attributes},
            {optional, 'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'}
        }
    ],
    M = #{
        attributes =>
            {schedule_activity_task_command_attributes, #{
                input => #{payloads => [?P]}, activity_id => "ID"
            }}
    },
    R = ?RI_REQ,
    CC = [
        {[temporal_sdk_codec_payload_erl], [
            'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'
        ]}
    ],
    MN = 'temporal.api.command.v1.Command',
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_rsp_cc1_test() ->
    P = [
        {
            {attributes, workflow_execution_started_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'}
        }
    ],
    M = #{
        attributes =>
            {workflow_execution_started_event_attributes, #{
                input => #{payloads => [?P_ERL]}, activity_id => "ID"
            }}
    },
    R = ?RI_RSP,
    CC = [
        {[temporal_sdk_codec_payload_erl], [
            'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'
        ]}
    ],
    MN = 'temporal.api.history.v1.HistoryEvent',
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_req_cc2_test() ->
    P = [
        {
            {attributes, schedule_activity_task_command_attributes},
            {optional, 'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'}
        }
    ],
    M = #{
        attributes =>
            {schedule_activity_task_command_attributes, #{
                input => #{payloads => [?P]}, activity_id => "ID"
            }}
    },
    R = ?RI_REQ,
    CC = [
        {[temporal_sdk_codec_payload_json], [
            'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'
        ]}
    ],
    MN = 'temporal.api.command.v1.Command',
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_rsp_cc2_test() ->
    P = [
        {
            {attributes, workflow_execution_started_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'}
        }
    ],
    M = #{
        attributes =>
            {workflow_execution_started_event_attributes, #{
                input => #{payloads => [?P_JSON]}, activity_id => "ID"
            }}
    },
    R = ?RI_RSP,
    CC = [
        {[temporal_sdk_codec_payload_json], [
            'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'
        ]}
    ],
    MN = 'temporal.api.history.v1.HistoryEvent',
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_req_cc3_test() ->
    P = [
        {
            {attributes, schedule_activity_task_command_attributes},
            {optional, 'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'}
        }
    ],
    M = #{
        attributes =>
            {schedule_activity_task_command_attributes, #{
                input => #{payloads => [?P]}, activity_id => "ID"
            }}
    },
    R = ?RI_REQ,
    CC = [
        {[temporal_sdk_codec_payload_json], [
            'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'
        ]},
        {[temporal_sdk_codec_payload_erl], [nokey]}
    ],
    MN = 'temporal.api.command.v1.Command',
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_rsp_cc3_test() ->
    P = [
        {
            {attributes, workflow_execution_started_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'}
        }
    ],
    M = #{
        attributes =>
            {workflow_execution_started_event_attributes, #{
                input => #{payloads => [?P_JSON]}, activity_id => "ID"
            }}
    },
    R = ?RI_RSP,
    CC = [
        {[temporal_sdk_codec_payload_json], [
            'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'
        ]},
        {[temporal_sdk_codec_payload_erl], [nokey]}
    ],
    MN = 'temporal.api.history.v1.HistoryEvent',
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_req_cc4_test() ->
    P = [
        {
            {attributes, schedule_activity_task_command_attributes},
            {optional, 'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'}
        }
    ],
    M = #{
        attributes =>
            {schedule_activity_task_command_attributes, #{
                input => #{payloads => [?P]}, activity_id => "ID"
            }}
    },
    R = ?RI_REQ,
    CC = [
        {[temporal_sdk_codec_payload_json], [nokey]},
        {[temporal_sdk_codec_payload_erl], [
            'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'
        ]}
    ],
    MN = 'temporal.api.command.v1.Command',
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_rsp_cc4_test() ->
    P = [
        {
            {attributes, workflow_execution_started_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'}
        }
    ],
    M = #{
        attributes =>
            {workflow_execution_started_event_attributes, #{
                input => #{payloads => [?P_ERL]}, activity_id => "ID"
            }}
    },
    R = ?RI_RSP,
    CC = [
        {[temporal_sdk_codec_payload_json], [nokey]},
        {[temporal_sdk_codec_payload_erl], [
            'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'
        ]}
    ],
    MN = 'temporal.api.history.v1.HistoryEvent',
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_req_cc5_test() ->
    P = [
        {
            {attributes, schedule_activity_task_command_attributes},
            {optional, 'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'}
        }
    ],
    M = #{
        attributes =>
            {schedule_activity_task_command_attributes, #{
                input => #{payloads => [?P]}, activity_id => "ID"
            }}
    },
    R = ?RI_REQ,
    CC = [
        {[temporal_sdk_codec_payload_erl], [
            {'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes', input}
        ]}
    ],
    MN = 'temporal.api.command.v1.Command',
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_rsp_cc5_test() ->
    P = [
        {
            {attributes, workflow_execution_started_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'}
        }
    ],
    M = #{
        attributes =>
            {workflow_execution_started_event_attributes, #{
                input => #{payloads => [?P_ERL]}, activity_id => "ID"
            }}
    },
    R = ?RI_RSP,
    CC = [
        {[temporal_sdk_codec_payload_erl], [
            {'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes', input}
        ]}
    ],
    MN = 'temporal.api.history.v1.HistoryEvent',
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_req_cc6_test() ->
    P = [
        {
            {attributes, schedule_activity_task_command_attributes},
            {optional, 'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'}
        }
    ],
    M = #{
        attributes =>
            {schedule_activity_task_command_attributes, #{
                input => #{payloads => [?P]}, activity_id => "ID"
            }}
    },
    R = ?RI_REQ,
    CC = [
        {[temporal_sdk_codec_payload_erl], [
            {'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes', nokey}
        ]}
    ],
    MN = 'temporal.api.command.v1.Command',
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_JSON]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_rsp_cc6_test() ->
    P = [
        {
            {attributes, workflow_execution_started_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'}
        }
    ],
    M = #{
        attributes =>
            {workflow_execution_started_event_attributes, #{
                input => #{payloads => [?P_ERL]}, activity_id => "ID"
            }}
    },
    R = ?RI_RSP,
    CC = [
        {[temporal_sdk_codec_payload_erl], [
            {'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes', nokey}
        ]}
    ],
    MN = 'temporal.api.history.v1.HistoryEvent',
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertMatch({error, _}, convert_paths(P, MN, M, c, R, CC, ?C_JSON)),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_req_cc7_test() ->
    P = [
        {
            {attributes, schedule_activity_task_command_attributes},
            {optional, 'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'}
        }
    ],
    M = #{
        attributes =>
            {schedule_activity_task_command_attributes, #{
                input => #{payloads => [?P]}, activity_id => "ID"
            }}
    },
    R = ?RI_REQ,
    CC = [
        {[temporal_sdk_codec_payload_erl], [
            {'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes', [input, nokey]}
        ]}
    ],
    MN = 'temporal.api.command.v1.Command',
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg3_rsp_cc7_test() ->
    P = [
        {
            {attributes, workflow_execution_started_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'}
        }
    ],
    M = #{
        attributes =>
            {workflow_execution_started_event_attributes, #{
                input => #{payloads => [?P_ERL]}, activity_id => "ID"
            }}
    },
    R = ?RI_RSP,
    CC = [
        {[temporal_sdk_codec_payload_erl], [
            {'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes', [input, nokey]}
        ]}
    ],
    MN = 'temporal.api.history.v1.HistoryEvent',
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg4_req_cc7_test() ->
    P = [
        {
            {attributes, schedule_activity_task_command_attributes},
            {optional, 'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes'}
        }
    ],
    M = #{
        attributes =>
            {schedule_activity_task_command_attributes, #{
                input => #{payloads => [?P, ?P]}, activity_id => "ID"
            }}
    },
    R = ?RI_REQ,
    CC = [
        {[temporal_sdk_codec_payload_erl], [
            {'temporal.api.command.v1.ScheduleActivityTaskCommandAttributes', [input, nokey]}
        ]}
    ],
    MN = 'temporal.api.command.v1.Command',
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL, ?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL, ?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL, ?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {schedule_activity_task_command_attributes, #{
                    input => #{payloads => [?P_ERL, ?P_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

convert_optional1_msg4_rsp_cc7_test() ->
    P = [
        {
            {attributes, workflow_execution_started_event_attributes},
            {optional, 'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes'}
        }
    ],
    M = #{
        attributes =>
            {workflow_execution_started_event_attributes, #{
                input => #{payloads => [?P_ERL, ?P_ERL]}, activity_id => "ID"
            }}
    },
    R = ?RI_RSP,
    CC = [
        {[temporal_sdk_codec_payload_erl], [
            {'temporal.api.history.v1.WorkflowExecutionStartedEventAttributes', [input, nokey]}
        ]}
    ],
    MN = 'temporal.api.history.v1.HistoryEvent',
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL, ?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL, ?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL, ?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{
            attributes =>
                {workflow_execution_started_event_attributes, #{
                    input => #{payloads => [?CP_ERL, ?CP_ERL]}, activity_id => "ID"
                }}
        }},
        convert_paths(P, MN, M, c, R, CC, ?C_BIN_JSON_ERL)
    ).

%% -------------------------------------------------------------------------------------------------
%% convert_payload/4

convert_payload_test() ->
    Data = ?DATA,
    ?assertError(_, convert_payload(#{data => ?DATA}, ?CL, ?RI_REQ, [invalid_codec])),
    ?assertError(_, convert_payload(#{data => ?DATA}, ?CL, ?RI_RSP, [invalid_codec])),

    ?assertMatch({error, _}, convert_payload(Data, ?CL, ?RI_REQ, ?C_ERL)),
    ?assertMatch({error, _}, convert_payload(Data, ?CL, ?RI_RSP, ?C_ERL)),
    ?assertMatch({error, _}, convert_payload(Data, ?CL, ?RI_REQ, ?C_JSON)),
    ?assertMatch({error, _}, convert_payload(Data, ?CL, ?RI_RSP, ?C_JSON)),
    ?assertMatch({error, _}, convert_payload(Data, ?CL, ?RI_REQ, ?C_JSON_ERL)),
    ?assertMatch({error, _}, convert_payload(Data, ?CL, ?RI_RSP, ?C_JSON_ERL)),
    ?assertMatch({error, _}, convert_payload(Data, ?CL, ?RI_REQ, ?C_BIN_JSON_ERL)),
    ?assertMatch({error, _}, convert_payload(Data, ?CL, ?RI_RSP, ?C_BIN_JSON_ERL)).

convert_payload_erl_test() ->
    ?assertEqual({ok, ?P_ERL}, convert_payload(?P, ?CL, ?RI_REQ, ?C_ERL)),
    ?assertEqual({ok, ?CP_ERL}, convert_payload(?P_ERL, ?CL, ?RI_RSP, ?C_ERL)).

convert_payload_json_test() ->
    ?assertEqual({ok, ?P_JSON}, convert_payload(?P, ?CL, ?RI_REQ, ?C_JSON)),
    ?assertEqual({ok, ?CP_JSON}, convert_payload(?P_JSON, ?CL, ?RI_RSP, ?C_JSON)),

    ?assertMatch({error, _}, convert_payload(#{data => {tuple1, tuple2}}, ?CL, ?RI_REQ, ?C_JSON)).

convert_payload_json_erl_test() ->
    ?assertEqual({ok, ?P_JSON}, convert_payload(?P, ?CL, ?RI_REQ, ?C_JSON_ERL)),
    ?assertEqual({ok, ?CP_JSON}, convert_payload(?P_JSON, ?CL, ?RI_RSP, ?C_JSON_ERL)),

    Data = {tuple1, tuple2},
    ConvertedData = erlang:term_to_binary(Data),
    ?assertEqual(
        {ok, #{data => ConvertedData, metadata => ?META_ERL}},
        convert_payload(#{data => Data}, ?CL, ?RI_REQ, ?C_JSON_ERL)
    ).

convert_payload_bin_json_erl_test() ->
    Data1 = <<"binary-test-data">>,
    ?assertEqual(
        {ok, #{data => Data1, metadata => ?META_BIN}},
        convert_payload(#{data => Data1}, ?CL, ?RI_REQ, ?C_BIN_JSON_ERL)
    ),
    ?assertEqual(
        {ok, #{data => Data1, metadata => ?META_BIN}},
        convert_payload(#{data => Data1, metadata => ?META_BIN}, ?CL, ?RI_RSP, ?C_BIN_JSON_ERL)
    ),

    ?assertEqual({ok, ?P_JSON}, convert_payload(?P, ?CL, ?RI_REQ, ?C_BIN_JSON_ERL)),
    ?assertEqual({ok, ?CP_JSON}, convert_payload(?P_JSON, ?CL, ?RI_RSP, ?C_BIN_JSON_ERL)),

    Data2 = {tuple1, tuple2},
    ConvertedData = erlang:term_to_binary(Data2),
    ?assertEqual(
        {ok, #{data => ConvertedData, metadata => ?META_ERL}},
        convert_payload(#{data => Data2}, ?CL, ?RI_REQ, ?C_BIN_JSON_ERL)
    ).

-endif.
