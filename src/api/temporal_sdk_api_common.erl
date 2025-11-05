-module(temporal_sdk_api_common).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    retry_policy/1,
    get_by_casted_key/4,
    mutation_reset_reason/1,
    marker_encode_value/2,
    marker_decode_value/2,
    run_request/5,
    format_response/4,
    t2e/3
]).

-include("proto.hrl").

-spec retry_policy(RetryPolicy :: temporal_sdk:retry_policy()) ->
    ?TEMPORAL_SPEC:'temporal.api.common.v1.RetryPolicy'().
retry_policy(RetryPolicy) ->
    RP1 =
        case RetryPolicy of
            #{initial_interval := II} ->
                RetryPolicy#{initial_interval := temporal_sdk_utils_time:msec_to_protobuf(II)};
            #{} ->
                RetryPolicy
        end,
    case RP1 of
        #{maximum_interval := MI} ->
            RP1#{maximum_interval := temporal_sdk_utils_time:msec_to_protobuf(MI)};
        #{} ->
            RP1
    end.

-spec get_by_casted_key(
    Key :: term(),
    Map :: map(),
    Default :: term(),
    ApiCtx :: temporal_sdk_api:context()
) -> {CastedKey :: unicode:chardata(), Value :: term()}.
get_by_casted_key(Key, Map, Default, #{client_opts := #{grpc_opts := #{codec := {Codec, _, _}}}}) ->
    CastedKey = Codec:cast(Key),
    case Map of
        #{CastedKey := V} -> {CastedKey, V};
        #{} -> {CastedKey, Default}
    end.

-spec mutation_reset_reason(Name :: unicode:chardata() | atom()) -> {string(), binary()}.
mutation_reset_reason(Name) ->
    Str = temporal_sdk_utils_path:string_path([?MUTATION_RESET_PREFIX, Name], ":"),
    {Str, temporal_sdk_utils_unicode:characters_to_binary1(Str)}.

-spec marker_encode_value(
    Codec :: temporal_sdk_workflow:marker_value_codec(),
    Value :: temporal_sdk:term_to_payloads() | term()
) ->
    {ok, EncodedValue :: temporal_sdk:term_to_payloads(),
        Decoder ::
            none
            | list
            | term
            | fun((temporal_sdk:term_from_payloads()) -> term())
            | {Module :: module(), Function :: atom()}}
    | {error, Reason :: map()}.
marker_encode_value(list, Value) ->
    {ok, [Value], list};
marker_encode_value(term, Value) ->
    {ok, [erlang:term_to_binary(Value)], term};
marker_encode_value(none, Value) when is_list(Value) ->
    {ok, Value, none};
marker_encode_value({none, none}, Value) when is_list(Value) ->
    {ok, Value, none};
marker_encode_value({none, DF}, Value) when is_list(Value), is_function(DF, 1) ->
    {ok, Value, DF};
marker_encode_value({none, {DM, DF}}, Value) when is_list(Value), is_atom(DM), is_atom(DF) ->
    {ok, Value, {DM, DF}};
marker_encode_value({EF, none}, Value) when is_function(EF, 1) ->
    case EF(Value) of
        EV when is_list(EV) -> {ok, EV, none};
        EV -> do_encode_type_err(EF, Value, EV)
    end;
marker_encode_value({{EM, EF}, none}, Value) when is_atom(EM), is_atom(EF) ->
    case EM:EF(Value) of
        EV when is_list(EV) -> {ok, EV, none};
        EV -> do_encode_type_err({EM, EF}, Value, EV)
    end;
marker_encode_value({EF, none}, Value) when is_function(EF, 1) ->
    case EF(Value) of
        EV when is_list(EV) -> {ok, EV, none};
        EV -> do_encode_type_err(EF, Value, EV)
    end;
marker_encode_value({EF, DF}, Value) when is_function(EF, 1), is_function(DF, 1) ->
    case EF(Value) of
        EV when is_list(EV) -> {ok, EV, none};
        EV -> do_encode_type_err(EF, Value, EV)
    end;
marker_encode_value({EF, {DM, DF}}, Value) when is_function(EF, 1), is_atom(DM), is_atom(DF) ->
    case EF(Value) of
        EV when is_list(EV) -> {ok, EV, {DM, DF}};
        EV -> do_encode_type_err(EF, Value, EV)
    end;
marker_encode_value(Codec, Value) ->
    {error, #{
        reason => "Invalid marker value type or invalid marker <value_codec> configuration.",
        marker_value => Value,
        marker_value_codec => Codec
    }}.

do_encode_type_err(Encoder, Value, EncodedValue) ->
    {error, #{
        reason => "Invalid encoded marker value type. Expected a list() type.",
        marker_value => Value,
        invalid_encoded_marker_value => EncodedValue,
        encoder => Encoder
    }}.

-spec marker_decode_value(
    Decoder ::
        none
        | list
        | term
        | fun((temporal_sdk:term_from_payloads()) -> term())
        | {Module :: module(), Function :: atom()},
    Value :: temporal_sdk:term_from_payloads()
) -> DecodedValue :: term().
marker_decode_value(list, [Value]) -> Value;
marker_decode_value(term, [Value]) -> erlang:binary_to_term(Value);
marker_decode_value(none, Value) -> Value;
marker_decode_value(DF, Value) when is_function(DF, 1) -> DF(Value);
marker_decode_value({DM, DF}, Value) when is_atom(DM), is_atom(DF) -> DM:DF(Value).

-spec run_request(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Opts :: proplists:proplist(),
    DefaultOpts :: temporal_sdk_utils_opts:defaults(),
    ServiceName :: temporal_sdk_api:temporal_service(),
    MessageName :: temporal_msg_name()
) -> temporal_sdk:response().
run_request(Cluster, Opts, DefaultOpts, ServiceName, MessageName) ->
    maybe
        {ok, ApiCtx} ?= temporal_sdk_api_context:build(Cluster),
        {ok, FullOpts} ?= temporal_sdk_utils_opts:build(DefaultOpts, Opts, ApiCtx),
        {RawRequest, O1} = maps:take(raw_request, FullOpts),
        {ResponseType, O2} = maps:take(response_type, O1),
        Req = maps:merge(O2, RawRequest),
        Response = temporal_sdk_api:request(ServiceName, Cluster, Req, ResponseType, #{}),
        format_response(MessageName, ResponseType, Response, ApiCtx)
    end.

-spec format_response(
    MessageName :: temporal_msg_name(),
    ResponseType :: temporal_sdk:response_type(),
    Response :: {ok, temporal_msg()} | {error, term()},
    ApiCtx :: temporal_sdk_api:context()
) -> temporal_sdk:response().
format_response(MessageName, call_formatted, {ok, Response}, ApiCtx) ->
    {ok, t2e(MessageName, Response, ApiCtx)};
format_response(
    _MessageName, call_formatted, {error, #{grpc_response_headers := H}}, _ApiCtx
) when is_list(H) ->
    Err =
        case proplists:get_value(~"grpc-message", H, '$_undefined') of
            '$_undefined' -> proplists:get_value("grpc-message", H, undefined);
            E -> E
        end,
    {error, Err};
format_response(_MessageName, _Opts, Response, _ApiCtx) ->
    Response.

-spec t2e(
    MessageName :: temporal_msg_name(),
    Message :: temporal_msg(),
    ApiCtx :: temporal_sdk_api:context()
) -> ConvertedMessage :: map().
t2e(MessageName, Message, ApiCtx) when is_map(Message) ->
    maps:from_list(te(MessageName, maps:to_list(Message), ApiCtx, [], [])).

te(MN, [{K, #{payloads := _} = V} | TM], ApiCtx, KAcc, Acc) ->
    te(MN, TM, ApiCtx, KAcc, [
        {K, temporal_sdk_api:map_from_payloads(ApiCtx, MN, KAcc ++ [K], V)} | Acc
    ]);
te(MN, [{K, #{data := _, metadata := _} = V} | TM], ApiCtx, KAcc, Acc) ->
    te(MN, TM, ApiCtx, KAcc, [
        {K, temporal_sdk_api:map_from_payload(ApiCtx, MN, KAcc ++ [K], V)} | Acc
    ]);
te(MN, [{header = K, #{fields := V}} | TM], ApiCtx, KAcc, Acc) ->
    te(MN, TM, ApiCtx, KAcc, [
        {K, temporal_sdk_api:map_from_mapstring_payload(ApiCtx, MN, KAcc ++ [K, fields], V)} | Acc
    ]);
te(MN, [{memo = K, #{fields := V}} | TM], ApiCtx, KAcc, Acc) ->
    te(MN, TM, ApiCtx, KAcc, [
        {K, temporal_sdk_api:map_from_mapstring_payload(ApiCtx, MN, KAcc ++ [K, fields], V)} | Acc
    ]);
te(MN, [{search_attributes = K, #{indexed_fields := V}} | TM], ApiCtx, KAcc, Acc) ->
    te(MN, TM, ApiCtx, KAcc, [
        {K, temporal_sdk_api:map_from_mapstring_payload(ApiCtx, MN, KAcc ++ [K, fields], V)} | Acc
    ]);
te(MN, [{workflow_type = K, #{name := N}} | TM], ApiCtx, KAcc, Acc) ->
    te(MN, TM, ApiCtx, KAcc, [{K, N} | Acc]);
te(MN, [{task_queue = K, #{name := N}} | TM], ApiCtx, KAcc, Acc) ->
    te(MN, TM, ApiCtx, KAcc, [{K, N} | Acc]);
te(MN, [{type = K, #{name := N}} | TM], ApiCtx, KAcc, Acc) ->
    te(MN, TM, ApiCtx, KAcc, [{K, N} | Acc]);
te(MN, [{K, #{seconds := _, nanos := _} = T} | TM], ApiCtx, KAcc, Acc) ->
    te(MN, TM, ApiCtx, KAcc, [{K, temporal_sdk_utils_time:protobuf_to_msec(T)} | Acc]);
te(MN, [{K, [#{} | _] = Li} | TM], ApiCtx, KAcc, Acc) ->
    V = lists:map(
        fun(M) when is_map(M) -> maps:from_list(te(MN, maps:to_list(M), ApiCtx, KAcc ++ [K], []))
        end,
        Li
    ),
    te(MN, TM, ApiCtx, KAcc, [{K, V} | Acc]);
te(MN, [{K, #{} = Ma} | TM], ApiCtx, KAcc, Acc) ->
    V = maps:from_list(te(MN, maps:to_list(Ma), ApiCtx, KAcc ++ [K], [])),
    te(MN, TM, ApiCtx, KAcc, [{K, V} | Acc]);
te(MN, [{K, {KT, #{} = Ma}} | TM], ApiCtx, KAcc, Acc) ->
    V = maps:from_list(te(MN, maps:to_list(Ma), ApiCtx, KAcc ++ [K], [])),
    te(MN, TM, ApiCtx, KAcc, [{K, {KT, V}} | Acc]);
te(MN, [KV | TM], ApiCtx, KAcc, Acc) ->
    te(MN, TM, ApiCtx, KAcc, [KV | Acc]);
te(_MN, [], _ApiCtx, _KAcc, Acc) ->
    Acc.
