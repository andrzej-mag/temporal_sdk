-module(temporal_sdk_utils_proto_converter).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    convert_paths/7,
    convert_payload/4
]).

-define(DEFAULT_CODEC_OPTS, []).

%% `convert_paths/7` and `convert_payload/4` functions are used exclusively by
%% `temporal_sdk_proto_converter` module.
%% In theory both functions should be defined as a local functions.
%% Because `temporal_sdk_proto_converter.erl` file is automatically generated and due to functions
%% complexity, functions are defined separately here.
%% Such solution introduces circular reference, however it simplifies code generation,
%% offers better maintainability and allows reasonable unit testing.

convert_paths([{PKey, {optional, PName}} | TPaths], MsgName, Msg, Cl, RI, CC, C) when
    is_atom(PKey)
->
    maybe
        {ok, ChiMsg} ?= is_map_with_mapkey(Msg, PKey),
        C1 = select_codecs(MsgName, PKey, CC, C),
        {ok, CvMsg} ?= temporal_sdk_proto_converter:convert(PName, ChiMsg, Cl, RI, CC, C1),
        convert_paths(TPaths, MsgName, Msg#{PKey := CvMsg}, Cl, RI, CC, C)
    else
        nokey -> convert_paths(TPaths, MsgName, Msg, Cl, RI, CC, C);
        invalid_type -> convert_error("map", MsgName, Msg, Cl, PKey);
        Err -> Err
    end;
convert_paths([{PKey, {repeated, PName}} | TPaths], MsgName, Msg, Cl, RI, CC, C) when
    is_atom(PKey)
->
    maybe
        {ok, ChiMsg} ?= is_map_with_listkey(Msg, PKey),
        C1 = select_codecs(MsgName, PKey, CC, C),
        CvFun = fun(CMsg) -> temporal_sdk_proto_converter:convert(PName, CMsg, Cl, RI, CC, C1) end,
        {ok, CvMsg} ?= temporal_sdk_utils_lists:map_if_ok(CvFun, ChiMsg),
        convert_paths(TPaths, MsgName, Msg#{PKey := CvMsg}, Cl, RI, CC, C)
    else
        nokey -> convert_paths(TPaths, MsgName, Msg, Cl, RI, CC, C);
        invalid_type -> convert_error("list", MsgName, Msg, Cl, PKey);
        Err -> Err
    end;
convert_paths([{PKey, {map_string, PName}} | TPaths], MsgName, Msg, Cl, RI, CC, C) when
    is_atom(PKey)
->
    maybe
        {ok, ChiMsg} ?= is_map_with_mapkey(Msg, PKey),
        C1 = select_codecs(MsgName, PKey, CC, C),
        CvFun = fun(_K, CMsg) ->
            temporal_sdk_proto_converter:convert(PName, CMsg, Cl, RI, CC, C1)
        end,
        {ok, CvMsg} ?= temporal_sdk_utils_maps:map_if_ok(CvFun, ChiMsg),
        convert_paths(TPaths, MsgName, Msg#{PKey := CvMsg}, Cl, RI, CC, C)
    else
        nokey -> convert_paths(TPaths, MsgName, Msg, Cl, RI, CC, C);
        invalid_type -> convert_error("map", MsgName, Msg, Cl, PKey);
        Err -> Err
    end;
convert_paths([{{PRootKey, PKey}, {optional, PName}} | TPaths], MsgName, Msg, Cl, RI, CC, C) when
    is_atom(PKey), is_atom(PRootKey)
->
    maybe
        {ok, {PKey, ChiMsg}} ?= is_map_with_tuplemapkey(Msg, PRootKey),
        C1 = select_codecs(MsgName, PRootKey, CC, C),
        {ok, CvMsg} ?= temporal_sdk_proto_converter:convert(PName, ChiMsg, Cl, RI, CC, C1),
        convert_paths(TPaths, MsgName, Msg#{PRootKey := {PKey, CvMsg}}, Cl, RI, CC, C)
    else
        {ok, {_NotMatchingPKey, _ChiMsg}} -> convert_paths(TPaths, MsgName, Msg, Cl, RI, CC, C);
        nokey -> convert_paths(TPaths, MsgName, Msg, Cl, RI, CC, C);
        invalid_type -> convert_error("tuple with map", MsgName, Msg, Cl, PKey);
        Err -> Err
    end;
convert_paths([], _MsgName, Msg, _Cl, _RI, _CC, _C) ->
    {ok, Msg}.

select_codecs(MsgName, Key, [{CustomCodecs, CustomMessages} | TCustomCodecs], Codecs) ->
    case proplists:get_value(MsgName, CustomMessages, undefined) of
        true ->
            CustomCodecs;
        FKey when FKey == Key -> CustomCodecs;
        FKeys when is_list(FKeys) ->
            case lists:member(Key, FKeys) of
                true -> CustomCodecs;
                false -> Codecs
            end;
        _UndefinedOrIgnoredFKey ->
            select_codecs(MsgName, Key, TCustomCodecs, Codecs)
    end;
select_codecs(_MsgName, _Key, [], Codecs) ->
    Codecs.

is_map_with_mapkey(Msg, Key) ->
    case Msg of
        #{Key := V} ->
            case is_map(V) of
                true -> {ok, V};
                false -> invalid_type
            end;
        _ ->
            nokey
    end.

is_map_with_listkey(Msg, Key) ->
    case Msg of
        #{Key := V} ->
            case is_list(V) of
                true -> {ok, V};
                false -> invalid_type
            end;
        _ ->
            nokey
    end.

is_map_with_tuplemapkey(Msg, Key) ->
    case Msg of
        #{Key := {K, V}} ->
            case is_map(V) of
                true -> {ok, {K, V}};
                false -> invalid_type
            end;
        _ ->
            nokey
    end.

convert_error(Text, MsgName, Msg, Cl, Key) ->
    {error, #{
        reason => "Invalid Temporal message format. Expected message key of <" ++ Text ++ "> type.",
        message_name => MsgName,
        cluster => Cl,
        invalid_message => Msg,
        invalid_key_name => Key
    }}.

convert_payload(Payload, Cluster, #{type := request} = RequestInfo, Codecs) ->
    do_convert_payload(Payload, Cluster, RequestInfo, Codecs, []);
convert_payload(Payload, Cluster, #{type := response} = RequestInfo, Codecs) ->
    do_convert_payload(Payload, Cluster, RequestInfo, lists:reverse(Codecs), []).

do_convert_payload(Payload, Cluster, #{type := Type} = RequestInfo, [C | TCodecs], Errors) ->
    {CodecMod, Opts} = fetch_codec_config(C, Type),
    case CodecMod:convert(Payload, Cluster, RequestInfo, Opts) of
        {ok, CPayload} ->
            {ok, CPayload};
        ignored ->
            do_convert_payload(Payload, Cluster, RequestInfo, TCodecs, Errors);
        Err ->
            ErrMsg = #{
                reason => "Codec error.",
                error => Err,
                codec_module => CodecMod,
                payload => Payload,
                cluster => Cluster,
                request_info => RequestInfo
            },
            do_convert_payload(Payload, Cluster, RequestInfo, TCodecs, [ErrMsg | Errors])
    end;
do_convert_payload(Payload, Cluster, RequestInfo, [], []) ->
    {error, #{
        reason => "Failed to convert Temporal Payload. Codec matching given payload not found.",
        payload => Payload,
        cluster => Cluster,
        request_info => RequestInfo
    }};
do_convert_payload(_Payload, _Cluster, _RequestInfo, [], Err) ->
    {error, Err}.

fetch_codec_config({CodecMod, Opts, _}, request) when is_atom(CodecMod) -> {CodecMod, Opts};
fetch_codec_config({CodecMod, _, Opts}, response) when is_atom(CodecMod) -> {CodecMod, Opts};
fetch_codec_config(CodecMod, _Type) when is_atom(CodecMod) ->
    {CodecMod, ?DEFAULT_CODEC_OPTS}.
