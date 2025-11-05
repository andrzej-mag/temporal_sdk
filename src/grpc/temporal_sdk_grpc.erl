-module(temporal_sdk_grpc).

% elp:ignore W0012 W0040
-moduledoc """
gRPC client module.
""".

-export([
    start_grpc/2,
    max_timeout/1,
    request/5,
    from_json/3,
    to_json/3,
    convert_request/4,
    convert_response/4
]).

-include("grpc.hrl").
-include("telemetry.hrl").

-define(EVENT_ORIGIN, grpc).

-type msg() :: dynamic().
-export_type([msg/0]).

-type msg_name() :: term().
-export_type([msg_name/0]).

-type rpc_name() :: term().
-export_type([rpc_name/0]).

-type cluster_name() :: atom().
-export_type([cluster_name/0]).

-type adapter() :: {AdapterModule :: module(), AdapterConfig :: term()}.
-export_type([adapter/0]).

-type converter() :: {ConverterModule :: module(), ConverterOpts :: term()}.
-export_type([converter/0]).

-type codec() :: {Module :: module(), EncodeOpts :: term(), DecodeOpts :: term()}.
-export_type([codec/0]).

-type compressor() ::
    {Module :: module(), CompressOpts :: term(), DecompressOpts :: term()}.
-export_type([compressor/0]).

-type interceptor() :: {
    Module :: module(), HandleRequestOpts :: term(), HandleResponseOpts :: term()
}.
-export_type([interceptor/0]).

-type retry_policy() ::
    disabled
    | #{
        initial_interval := pos_integer(),
        backoff_coefficient := pos_integer(),
        maximum_interval := pos_integer(),
        max_attempts := pos_integer(),
        is_retryable := fun(
            (Result :: result(), RequestInfo :: request_info(), Attempt :: pos_integer()) ->
                boolean()
        )
    }.
-export_type([retry_policy/0]).

-type headers() ::
    [{nonempty_binary() | string() | atom(), iodata()}]
    | #{nonempty_binary() | string() | atom() => iodata()}.
-export_type([headers/0]).

-type opts() :: #{
    converter => converter(),
    codec => codec(),
    compressor => compressor(),
    interceptor => interceptor(),
    timeout => non_neg_integer(),
    retry_policy => retry_policy(),
    headers => headers(),
    maximum_request_size => pos_integer()
}.
-export_type([opts/0]).

-type result_success() :: {ok, ResponseMsg :: temporal_sdk_grpc:msg()}.
-export_type([result_success/0]).

-type result_error() :: {error, Reason :: term()}.
-export_type([result_error/0]).

-type result() :: result_success() | result_error().
-export_type([result/0]).

-type request_info() ::
    #{
        type := request | response,
        content_type := binary(),
        input := atom(),
        input_stream := boolean(),
        output := atom(),
        output_stream := boolean(),
        msg_type := binary(),
        name := atom(),
        opts := list(),
        service_fqname := atom()
    }.
-export_type([request_info/0]).

%% -------------------------------------------------------------------------------------------------
%% public

-spec start_grpc(Cluster :: cluster_name(), Adapter :: adapter()) -> ok | {error, term()}.
start_grpc(Cluster, {AdapterModule, AdapterConfig}) ->
    temporal_sdk_grpc_opts:init_opts(Cluster, AdapterModule),
    temporal_sdk_grpc_adapter:init_adapter(AdapterModule, Cluster, AdapterConfig).

-spec max_timeout(Opts :: opts()) -> pos_integer().
max_timeout(#{
    timeout := Timeout,
    retry_policy := #{
        max_attempts := MaxAttempts,
        backoff_coefficient := BackoffCoefficient,
        initial_interval := InitialInterval,
        maximum_interval := MaximumInterval
    }
}) ->
    {_, MaxT} = lists:foldl(
        fun(_C, {Interval, AccT}) when is_integer(Interval), is_integer(AccT) ->
            NewAccT = AccT + Interval + Timeout,
            NewInterval =
                case MaximumInterval of
                    0 -> Interval * BackoffCoefficient;
                    M -> min(Interval * BackoffCoefficient, M)
                end,
            {NewInterval, NewAccT}
        end,
        {InitialInterval, Timeout},
        lists:seq(1, MaxAttempts - 1)
    ),
    MaxT;
max_timeout(#{timeout := Timeout, retry_policy := disabled}) ->
    Timeout.

-spec request(
    From :: erlang:send_destination() | noreply,
    Cluster :: cluster_name(),
    Msg :: msg(),
    Opts :: opts(),
    RequestInfo :: request_info()
) -> ok.
request(
    From,
    Cluster,
    Msg,
    #{retry_policy := RetryPolicy} = Opts,
    #{name := RpcName} = RequestInfo
) when is_map(RetryPolicy); RetryPolicy == disabled ->
    proc_lib:set_label(RpcName),
    case RetryPolicy of
        disabled ->
            request(From, Cluster, Msg, Opts, RequestInfo, disabled);
        #{initial_interval := InitialInterval} ->
            request(From, Cluster, Msg, Opts, RequestInfo, {1, InitialInterval})
    end;
request(From, _Cluster, _Msg, _Opts, _RequestInfo) ->
    maybe_reply(
        From, {error, {invalid_opts, "Invalid <opts> or <request_info>."}}
    ).

-spec from_json(Json :: map(), MsgName :: msg_name(), Opts :: opts()) ->
    {ok, msg()} | {error, Reason :: term()}.
from_json(Json, MsgName, Opts) ->
    #{codec := {Codec, _EncodeOpts, DecodeOpts}} = Opts,
    temporal_sdk_grpc_codec:from_json(Codec, Json, MsgName, DecodeOpts).

-spec to_json(Msg :: msg(), MsgName :: msg_name(), Opts :: opts()) ->
    {ok, map()} | {error, Reason :: term()}.
to_json(Json, MsgName, Opts) ->
    #{codec := {Codec, EncodeOpts, _DecodeOpts}} = Opts,
    temporal_sdk_grpc_codec:to_json(Codec, Json, MsgName, EncodeOpts).

-spec convert_request(
    Cluster :: cluster_name(),
    Msg :: msg(),
    MsgName :: atom(),
    Opts :: opts()
) -> {ok, ConvertedMsg :: msg()} | {error, Reason :: term()}.
convert_request(Cluster, Msg, MsgName, Opts) ->
    RequestInfo = #{
        type => request,
        content_type => <<>>,
        input => MsgName,
        input_stream => false,
        output => undefined,
        output_stream => false,
        msg_type => <<>>,
        name => undefined,
        opts => [],
        service_fqname => undefined
    },
    temporal_sdk_grpc_converter:run(Cluster, Msg, RequestInfo, Opts).

-spec convert_response(
    Cluster :: cluster_name(),
    Msg :: msg(),
    MsgName :: atom(),
    Opts :: opts()
) -> {ok, ConvertedMsg :: msg()} | {error, Reason :: term()}.
convert_response(Cluster, Msg, MsgName, Opts) ->
    ResponseInfo = #{
        type => response,
        content_type => <<>>,
        input => undefined,
        input_stream => false,
        output => MsgName,
        output_stream => false,
        msg_type => <<>>,
        name => undefined,
        opts => [],
        service_fqname => undefined
    },
    temporal_sdk_grpc_converter:run(Cluster, Msg, ResponseInfo, Opts).

%% -------------------------------------------------------------------------------------------------
%% private

-spec request(
    From :: erlang:send_destination() | noreply,
    Cluster :: cluster_name(),
    Msg :: msg(),
    Opts :: opts(),
    RequestInfo :: request_info(),
    {Attempt :: pos_integer(), Interval :: pos_integer()} | disabled
) -> ok.
request(
    From,
    Cluster,
    Msg,
    #{retry_policy := RetryPolicy} = Opts,
    RequestInfo,
    Attempt_Interval
) ->
    Result = do_request(Cluster, Msg, Opts, RequestInfo),
    maybe
        %% pattern match is done here to cover `disabled` retry_policy case
        {Attempt, Interval} ?= Attempt_Interval,
        #{
            max_attempts := MaxAttempts,
            backoff_coefficient := BackoffCoefficient,
            maximum_interval := MaximumInterval,
            is_retryable := IsRetryable
        } ?= RetryPolicy,
        true ?= IsRetryable(Result, RequestInfo, Attempt),
        true ?= Attempt < MaxAttempts,
        %% surrogate for timer:sleep(Interval)
        receive
        after Interval -> ok
        end,
        NewInterval = update_interval(Interval, BackoffCoefficient, MaximumInterval),
        request(From, Cluster, Msg, Opts, RequestInfo, {Attempt + 1, NewInterval})
    else
        _ ->
            maybe_reply(From, Result)
    end.

maybe_reply(noreply, _Result) ->
    ok;
maybe_reply(From, Result) ->
    From ! {?TEMPORAL_GRPC_MSG_TAG, self(), Result},
    ok.

update_interval(Interval, BackoffCoefficient, MaximumInterval) ->
    min(Interval * BackoffCoefficient, MaximumInterval).

-spec do_request(
    Cluster :: cluster_name(),
    Msg :: msg(),
    Opts :: opts(),
    RequestInfo :: request_info()
) ->
    result().
do_request(Cluster, Msg0, Opts, RequestInfo) ->
    Metadata = #{
        cluster => Cluster,
        request_name => map_get(name, RequestInfo)
    },
    T = ?EV(Metadata, [start]),
    maybe
        %% request preparation
        {ok, Msg1} ?= temporal_sdk_grpc_interceptor:run(Cluster, Msg0, RequestInfo, Opts),
        {ok, Msg2} ?= temporal_sdk_grpc_converter:run(Cluster, Msg1, RequestInfo, Opts),
        {ok, Path, Headers, Body} ?= encode_compress_request(Cluster, Msg2, RequestInfo, Opts),
        ok ?= check_message_size(byte_size(Body), Opts),
        %% request
        {ok, REndpoint, RMsg, RHeaders} ?=
            temporal_sdk_grpc_adapter:request(Cluster, ~"POST", Path, Headers, Body, Opts),
        %% response processing
        ResponseInfo = RequestInfo#{type := response},
        {ok, Response1} ?= decompress_decode_response(Cluster, RMsg, RHeaders, ResponseInfo, Opts),
        {ok, Response2} ?= temporal_sdk_grpc_converter:run(Cluster, Response1, ResponseInfo, Opts),
        {ok, Response} ?= temporal_sdk_grpc_interceptor:run(Cluster, Response2, ResponseInfo, Opts),
        ?EV(Metadata#{endpoint => REndpoint}, [stop], T),
        {ok, Response}
    else
        {request_error, Endpoint, Error} ->
            ?EV(Metadata#{endpoint => Endpoint}, [exception], T, {error, Error, []}),
            temporal_sdk_utils_error:normalize_error(Error);
        Error ->
            ?EV(Metadata#{endpoint => undefined}, [exception], T, {error, Error, []}),
            temporal_sdk_utils_error:normalize_error(Error)
    end.

check_message_size(Size, #{maximum_request_size := MaxSize}) when Size > MaxSize ->
    {error, #{
        reason => maximum_request_size_exceeded,
        size => Size,
        maximum_request_size => MaxSize
    }};
check_message_size(_Size, _Opts) ->
    ok.

encode_compress_request(
    Cluster,
    Msg,
    #{
        input_stream := false,
        name := RpcName,
        output := _Output,
        output_stream := false,
        msg_type := MsgType,
        content_type := ContentType,
        service_fqname := ServiceFqname
    } = RequestInfo,
    #{
        codec := {Codec, EncodeOpts, _DecodeOpts},
        timeout := Timeout,
        headers := UserHeaders
    } = Opts
) ->
    case temporal_sdk_grpc_codec:encode_msg(Codec, Msg, RequestInfo, EncodeOpts) of
        {ok, EncMsg} ->
            {CompressedMsg, CompressedFlag, CompressedHeader} =
                temporal_sdk_grpc_compressor:compress(Cluster, EncMsg, RequestInfo, Opts),

            RpcFqBin = atom_to_binary(ServiceFqname),
            RpcNameBin = atom_to_binary(RpcName),
            Path = <<"/", RpcFqBin/binary, "/", RpcNameBin/binary>>,

            Length = byte_size(CompressedMsg),
            Body = <<CompressedFlag:8, Length:32, CompressedMsg/binary>>,
            Timeout1 = <<(integer_to_binary(floor(Timeout * 0.95)))/binary, "m">>,
            Headers = parse_headers(UserHeaders, ContentType, CompressedHeader, MsgType, Timeout1),

            {ok, Path, Headers, Body};
        Err ->
            Err
    end;
encode_compress_request(_Cluster, _Msg, _RequestInfo, _Opts) ->
    {error, {invalid_opts, "Invalid or missing <opts> or <request_info>."}}.

parse_headers(UserHeaders, ContentType, CompressedHeader, MsgType, Timeout) when
    is_list(UserHeaders)
->
    parse_headers(proplists:to_map(UserHeaders), ContentType, CompressedHeader, MsgType, Timeout);
parse_headers(UserHeaders, ContentType, CompressedHeader, MsgType, Timeout) when
    is_map(UserHeaders)
->
    GrpcHeaders =
        #{
            ~"content-type" => ContentType,
            ~"grpc-encoding" => CompressedHeader,
            ~"grpc-message-type" => MsgType,
            ~"grpc-timeout" => Timeout
        },
    maps:merge(GrpcHeaders, UserHeaders).

decompress_decode_response(Cluster, Body, Headers, RequestInfo, Opts) ->
    #{codec := {Codec, _EncodeOpts, DecodeOpts}} = Opts,
    case Body of
        <<0, Length:32, Encoded:Length/binary>> ->
            temporal_sdk_grpc_codec:decode_msg(
                Codec, Encoded, RequestInfo, fetch_content_type(Headers), DecodeOpts
            );
        <<1, Length:32, CompressedEncoded:Length/binary>> ->
            Encoded = temporal_sdk_grpc_compressor:decompress(
                Cluster, CompressedEncoded, RequestInfo, Opts
            ),
            temporal_sdk_grpc_codec:decode_msg(
                Codec, Encoded, RequestInfo, fetch_content_type(Headers), DecodeOpts
            );
        _ ->
            {error, malformed_grpc_response}
    end.

fetch_content_type([{~"content-type", ContentType} | _]) when is_binary(ContentType) ->
    ContentType.

%% -------------------------------------------------------------------------------------------------
%% telemetry

ev_origin() -> ?EVENT_ORIGIN.

ev_metadata(Metadata) -> Metadata.
