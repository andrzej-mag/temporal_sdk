-module(temporal_sdk_api_header).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    put_key/5,
    fetch/3,
    take_otel_ctx/1,
    put_sdk/4,
    get_sdk/4,
    put_marker_sdk/5
]).

-include("proto.hrl").

-spec put_key(
    RequestWithMaybeUserHeader :: temporal_sdk_client:msg(),
    Data :: temporal_sdk:term_to_payload(),
    Key :: unicode:chardata(),
    MsgName :: temporal_sdk_client:msg_name(),
    ApiCtx :: temporal_sdk_api:context()
) -> RequestWithSDKData :: map().
put_key(#{header := #{fields := #{} = RHF}} = R, Data, Key, MsgName, ApiCtx) ->
    R#{header := #{fields => maps:merge(RHF, do_map_to(Data, Key, MsgName, ApiCtx))}};
put_key(#{} = R, Data, Key, MsgName, ApiCtx) ->
    R#{header => #{fields => do_map_to(Data, Key, MsgName, ApiCtx)}}.

do_map_to(Data, Key, MsgName, ApiCtx) ->
    temporal_sdk_api:map_to_mapstring_payload(ApiCtx, MsgName, [header, fields], #{Key => Data}).

-spec fetch(
    Task :: temporal_sdk_client:msg(),
    MsgName :: temporal_sdk_client:msg_name(),
    ApiCtx :: temporal_sdk_api:context()
) -> HeaderFields :: temporal_sdk:term_from_mapstring_payload().
fetch(Task, MsgName, ApiCtx) ->
    case Task of
        #{header := #{fields := HF}} ->
            temporal_sdk_api:map_from_mapstring_payload(ApiCtx, MsgName, [header, fields], HF);
        #{} ->
            #{}
    end.

-spec take_otel_ctx(Header :: temporal_sdk:term_from_mapstring_payload() | list()) ->
    {TraceParent :: undefined | list(), HeaderNoOtel :: temporal_sdk:term_from_mapstring_payload()}.
take_otel_ctx(#{?TASK_HEADER_KEY_OTEL_TRACE := #{} = TraceParent} = Header) ->
    {proplists:from_map(TraceParent), maps:remove(?TASK_HEADER_KEY_OTEL_TRACE, Header)};
take_otel_ctx(#{?TASK_HEADER_KEY_OTEL_TRACE_BIN := #{} = TraceParent} = Header) ->
    {proplists:from_map(TraceParent), maps:remove(?TASK_HEADER_KEY_OTEL_TRACE_BIN, Header)};
take_otel_ctx(#{} = Header) ->
    {undefined, Header}.

-spec put_sdk(
    RequestWithMaybeUserHeader :: temporal_sdk_client:msg(),
    SDKData :: temporal_sdk:term_to_mapstring_payload(),
    MsgName :: temporal_sdk_client:msg_name(),
    ApiCtx :: temporal_sdk_api:context()
) -> RequestWithSDKData :: map().
put_sdk(#{header := #{fields := #{} = RHF}} = R, #{} = SDKD, MsgName, ApiCtx) when
    map_size(SDKD) > 0
->
    R#{header := #{fields => maps:merge(RHF, do_map_to(SDKD, MsgName, ApiCtx))}};
put_sdk(#{} = R, #{} = SDKD, MsgName, ApiCtx) when map_size(SDKD) > 0 ->
    R#{header => #{fields => do_map_to(SDKD, MsgName, ApiCtx)}};
put_sdk(#{} = R, _SDKData, _MsgName, _ApiCtx) ->
    R.

do_map_to(SDKData, MsgName, ApiCtx) ->
    temporal_sdk_api:map_to_mapstring_payload(
        ApiCtx, MsgName, [header, fields], #{
            ?TASK_HEADER_KEY_SDK_DATA => erlang:term_to_binary(SDKData)
        }
    ).

-spec get_sdk(
    DefaultSDKData :: map(),
    Task :: map(),
    MsgName :: temporal_sdk_client:msg_name(),
    ApiCtx :: temporal_sdk_api:context()
) -> {UserData :: #{header => temporal_sdk:term_from_mapstring_payload()}, SDKHeader :: map()}.
get_sdk(DefaultSDK, Task, MsgName, ApiCtx) ->
    {UserHeader, SDKH} = get_sdk(Task, MsgName, ApiCtx),
    SDKHeader = maps:merge(DefaultSDK, SDKH),
    case map_size(UserHeader) of
        0 -> {#{}, SDKHeader};
        _ -> {#{header => UserHeader}, SDKHeader}
    end.

-spec get_sdk(
    Task :: map(),
    MsgName :: temporal_sdk_client:msg_name(),
    ApiCtx :: temporal_sdk_api:context()
) -> {UserHeader :: temporal_sdk:term_from_mapstring_payload(), SDKHeader :: map()}.
get_sdk(Task, MsgName, ApiCtx) ->
    HeaderPayload = maps:get(fields, maps:get(header, Task, #{}), #{}),
    Header = temporal_sdk_api:map_from_mapstring_payload(
        ApiCtx, MsgName, [header, fields], HeaderPayload
    ),
    {CastedSDKKey, EncSDKHeader} =
        temporal_sdk_api_common:get_by_casted_key(?TASK_HEADER_KEY_SDK_DATA, Header, #{}, ApiCtx),
    SDKHeader = decode_sdk_data(EncSDKHeader),
    UserHeader = maps:without([CastedSDKKey], Header),
    {UserHeader, SDKHeader}.

decode_sdk_data(#{} = V) ->
    V;
decode_sdk_data(EncHeadersData) ->
    try
        case erlang:binary_to_term(EncHeadersData) of
            M when is_map(M) -> M;
            _ -> #{}
        end
    catch
        _Class:_Exception -> #{}
    end.

-spec put_marker_sdk(
    RequestAttr :: ?TEMPORAL_SPEC:'temporal.api.command.v1.RecordMarkerCommandAttributes'(),
    MarkerAttrOpts :: map(),
    Type :: temporal_sdk:convertable(),
    Decoder ::
        none
        | list
        | dlist
        | term
        | fun((temporal_sdk:term_from_payloads()) -> term())
        | {Module :: module(), Function :: atom()},
    ApiCtx :: temporal_sdk_api:context()
) -> RequestAttrWithSDK :: ?TEMPORAL_SPEC:'temporal.api.command.v1.RecordMarkerCommandAttributes'().
put_marker_sdk(RequestAttr, #{mutable := Mutable}, Type, Decoder, ApiCtx) ->
    MsgName = 'temporal.api.command.v1.RecordMarkerCommandAttributes',
    H1 =
        case Type of
            none -> #{};
            T -> #{type => T}
        end,
    H2 =
        case Mutable of
            false -> H1;
            Mu -> H1#{mutable => Mu}
        end,
    H =
        case Decoder of
            none -> H2;
            D -> H2#{decoder => D}
        end,
    put_sdk(RequestAttr, H, MsgName, ApiCtx).
