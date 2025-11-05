-module(temporal_sdk_client).
-behaviour(gen_server).

% elp:ignore W0012 W0040
-moduledoc """
SDK gRPC client module.
""".

-export([
    request/5
]).
-export([
    start_link/2,
    request_with_ctx/6
]).
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2
]).

-include("sdk.hrl").
-include("grpc.hrl").
-include("proto.hrl").

-type opts() :: #{
    adapter => temporal_sdk_grpc:adapter(),
    pool_size => pos_integer(),
    pool_strategy => round_robin | random,
    grpc_opts => grpc_opts(),
    grpc_opts_longpoll => grpc_opts(),
    helpers => helpers()
}.
-export_type([opts/0]).

-type user_opts() :: [
    {adapter, temporal_sdk_grpc:adapter()}
    | {pool_size, pos_integer()}
    | {pool_strategy, round_robin | random}
    | {grpc_opts, grpc_opts()}
    | {grpc_opts_longpoll, grpc_opts()}
    | {helpers, helpers()}
].
-export_type([user_opts/0]).

-type msg() :: temporal_msg().
-export_type([msg/0]).

-type msg_name() :: temporal_msg_name().
-export_type([msg_name/0]).

-type grpc_opts() :: temporal_sdk_grpc:opts().
-export_type([grpc_opts/0]).

-type request_type() :: call | cast | msg.
-export_type([request_type/0]).

-type request_error() ::
    {error, timeout | {invalid_opts, Details :: term()} | invalid_cluster | invalid_request_type}.

-type call_result_success() :: {ok, dynamic()}.
-export_type([call_result_success/0]).

-type call_result_error() :: temporal_sdk_grpc:result_error() | request_error().
-export_type([call_result_error/0]).

-type call_result() :: call_result_success() | call_result_error().
-export_type([call_result/0]).

-type cast_result() :: ok | request_error().
-export_type([cast_result/0]).

-type msg_result() :: reference() | request_error().
-export_type([msg_result/0]).

-type result() :: call_result() | cast_result() | msg_result().
-export_type([result/0]).

-type to_payload_mapper() :: fun(
    (
        Cluster :: temporal_sdk_cluster:cluster_name(),
        MsgName :: msg_name(),
        Key :: term(),
        Position :: pos_integer(),
        Data :: temporal_sdk:term_to_payload()
    ) -> Payload :: temporal_sdk:temporal_payload()
).
-export_type([to_payload_mapper/0]).

-type from_payload_mapper() :: fun(
    (
        Cluster :: temporal_sdk_cluster:cluster_name(),
        MsgName :: msg_name(),
        Key :: term(),
        Position :: pos_integer(),
        Data :: temporal_sdk:temporal_payload()
    ) -> Arg :: temporal_sdk:term_from_payload()
).
-export_type([from_payload_mapper/0]).

-type helpers() :: #{
    id => fun(
        (
            Cluster :: temporal_sdk_cluster:cluster_name(),
            MsgName :: msg_name(),
            IdKey :: term(),
            Msg :: map()
        ) -> unicode:chardata()
    ),
    identity => fun(
        (
            Cluster :: temporal_sdk_cluster:cluster_name(),
            Id :: temporal_sdk:serializable(),
            MsgName :: msg_name()
        ) -> unicode:chardata()
    ),
    to_payload_mapper => to_payload_mapper(),
    from_payload_mapper => from_payload_mapper(),
    serializer => fun(
        (
            Cluster :: temporal_sdk_cluster:cluster_name(),
            MsgName :: temporal_sdk_client:msg_name() | 'temporal.api.command.v1.*' | atom(),
            Key :: term(),
            Term :: temporal_sdk:serializable()
        ) -> unicode:chardata()
    )
}.

-record(req_info, {
    from :: gen_server:from() | pid() | noreply,
    req_proc_pid :: pid(),
    type :: call | cast | {msg, reference()},
    timer_ref :: reference()
}).
-type req_info() :: #req_info{}.

-record(state, {
    cluster :: temporal_sdk_cluster:cluster_name(),
    req_queue = [] :: [req_info()]
}).

%% gRPC requests timeouts should be fully covered by a http2 adapter.
%% Timeouts implemented here can be considered as a last line of defence against misbehaving
%% http2 adapters.
-define(TIMEOUT_RATIO, 1.5).
-define(CALL_TIMEOUT_RATIO, 2).

-define(INTERNAL_REQUEST_MSG_TAG, temporal_sdk_internal_grpc_request).

%% -------------------------------------------------------------------------------------------------
%% public

-spec request
    (
        Cluster :: temporal_sdk_cluster:cluster_name(),
        Msg :: msg(),
        Type,
        GrpcOpts :: grpc_opts(),
        RequestInfo :: temporal_sdk_grpc:request_info()
    ) ->
        Result :: call_result()
    when
        Type :: call;
    (
        Cluster :: temporal_sdk_cluster:cluster_name(),
        Msg :: msg(),
        Type,
        GrpcOpts :: grpc_opts(),
        RequestInfo :: temporal_sdk_grpc:request_info()
    ) ->
        Result :: cast_result()
    when
        Type :: cast;
    (
        Cluster :: temporal_sdk_cluster:cluster_name(),
        Msg :: msg(),
        Type,
        GrpcOpts :: grpc_opts(),
        RequestInfo :: temporal_sdk_grpc:request_info()
    ) ->
        Result :: msg_result()
    when
        Type :: msg.
request(Cluster, Msg, Type, GrpcOpts, RequestInfo) ->
    case temporal_sdk_cluster:is_alive(Cluster) of
        true ->
            do_request(
                Cluster,
                Msg,
                Type,
                GrpcOpts,
                RequestInfo,
                temporal_sdk_grpc:max_timeout(GrpcOpts),
                otel_ctx:get_current()
            );
        Err ->
            Err
    end.

%% -------------------------------------------------------------------------------------------------
%% gen_server

-doc false.
-spec start_link(Cluster :: temporal_sdk_cluster:cluster_name(), Worker :: integer()) ->
    gen_server:start_ret().
start_link(Cluster, W) ->
    gen_server:start_link(
        {local, temporal_sdk_utils_path:atom_path([?MODULE, Cluster, W])}, ?MODULE, [Cluster], []
    ).

-doc false.
init([Cluster]) ->
    process_flag(trap_exit, true),
    State = #state{cluster = Cluster},
    {ok, State}.

-doc false.
handle_call(
    {?INTERNAL_REQUEST_MSG_TAG, {Msg, Opts, RequestInfo, OtelCtx, Timeout}}, From, State
) ->
    handle_request(call, From, Msg, Opts, RequestInfo, OtelCtx, Timeout, State).

-doc false.
handle_cast(
    {?INTERNAL_REQUEST_MSG_TAG, Ref, From, {Msg, Opts, RequestInfo, OtelCtx, Timeout}}, State
) ->
    handle_request({msg, Ref}, From, Msg, Opts, RequestInfo, OtelCtx, Timeout, State).

-doc false.
handle_info({timeout, _TimerRef, Pid}, State) ->
    erlang:exit(Pid, {shutdown, timeout}),
    handle_response(Pid, timeout, State);
handle_info({?TEMPORAL_GRPC_MSG_TAG, Pid, Result}, State) ->
    handle_response(Pid, Result, State);
handle_info({'EXIT', _Pid, normal}, State) ->
    {noreply, State};
handle_info({'EXIT', Pid, Reason}, State) ->
    Result = temporal_sdk_utils_error:normalize_error(Reason),
    handle_response(Pid, Result, State).

handle_request(Type, From, Msg, Opts, RequestInfo, OtelCtx, Timeout, State) ->
    ReqPid = spawn_link(
        ?MODULE,
        request_with_ctx,
        [self(), State#state.cluster, Msg, Opts, RequestInfo, OtelCtx]
    ),
    TimerRef = erlang:start_timer(round(Timeout * ?TIMEOUT_RATIO), self(), ReqPid),
    Req = #req_info{from = From, req_proc_pid = ReqPid, type = Type, timer_ref = TimerRef},
    State1 = State#state{req_queue = [Req | State#state.req_queue]},
    {noreply, State1}.

handle_response(Pid, Result, State) ->
    {value, #req_info{from = From, req_proc_pid = Pid, type = Type, timer_ref = TimerRef}, ReqQueue} =
        lists:keytake(Pid, 3, State#state.req_queue),
    NormResult =
        case Result of
            timeout ->
                {error, timeout};
            _ ->
                erlang:cancel_timer(TimerRef),
                Result
        end,
    case Type of
        % eqwalizer:ignore
        call -> gen_server:reply(From, NormResult);
        % eqwalizer:ignore
        {msg, Ref} -> From ! {?TEMPORAL_SDK_GRPC_TAG, Ref, NormResult}
    end,
    State1 = State#state{req_queue = ReqQueue},
    {noreply, State1}.

%% -------------------------------------------------------------------------------------------------
%% private

-spec do_request
    (
        Cluster :: temporal_sdk_cluster:cluster_name(),
        Msg :: msg(),
        Type,
        GrpcOpts :: grpc_opts(),
        RequestInfo :: temporal_sdk_grpc:request_info(),
        Timeout :: pos_integer(),
        OtelCtx :: otel_ctx:t()
    ) ->
        Result :: call_result()
    when
        Type :: call;
    (
        Cluster :: temporal_sdk_cluster:cluster_name(),
        Msg :: msg(),
        Type,
        GrpcOpts :: grpc_opts(),
        RequestInfo :: temporal_sdk_grpc:request_info(),
        Timeout :: pos_integer(),
        OtelCtx :: otel_ctx:t()
    ) ->
        Result :: cast_result()
    when
        Type :: cast;
    (
        Cluster :: temporal_sdk_cluster:cluster_name(),
        Msg :: msg(),
        Type,
        GrpcOpts :: grpc_opts(),
        RequestInfo :: temporal_sdk_grpc:request_info(),
        Timeout :: pos_integer(),
        OtelCtx :: otel_ctx:t()
    ) ->
        Result :: msg_result()
    when
        Type :: msg.
do_request(Cluster, Msg, call, Opts, RequestInfo, Timeout, OtelCtx) ->
    case pick_worker(Cluster) of
        {ok, Worker} ->
            gen_server:call(
                Worker,
                {?INTERNAL_REQUEST_MSG_TAG, {Msg, Opts, RequestInfo, OtelCtx, Timeout}},
                round(Timeout * ?CALL_TIMEOUT_RATIO)
            );
        Err ->
            Err
    end;
do_request(Cluster, Msg, cast, Opts, RequestInfo, Timeout, OtelCtx) ->
    Pid = spawn(?MODULE, request_with_ctx, [noreply, Cluster, Msg, Opts, RequestInfo, OtelCtx]),
    temporal_sdk_utils_proc:exit_after(round(Timeout * ?TIMEOUT_RATIO), Pid);
do_request(Cluster, Msg, msg, Opts, RequestInfo, Timeout, OtelCtx) ->
    case pick_worker(Cluster) of
        {ok, Worker} ->
            Ref = make_ref(),
            gen_server:cast(
                Worker,
                {?INTERNAL_REQUEST_MSG_TAG, Ref, self(), {Msg, Opts, RequestInfo, OtelCtx, Timeout}}
            ),
            Ref;
        Err ->
            Err
    end;
do_request(_Cluster, _Msg, _Invalid, _Opts, _RequestInfo, _Timeout, _OtelCtx) ->
    {error, invalid_request_type}.

-spec pick_worker(Cluster :: temporal_sdk_cluster:cluster_name()) ->
    {ok, atom()}
    | {error, invalid_cluster}
    | {error, {invalid_opts, Reason :: term()}}.
pick_worker(Cluster) ->
    case temporal_sdk_client_opts:pick_worker_id(Cluster) of
        {ok, W} -> {ok, temporal_sdk_utils_path:atom_path([?MODULE, Cluster, W])};
        Err -> Err
    end.

-doc false.
request_with_ctx(From, Cluster, Msg, Opts, RequestInfo, OtelCtx) ->
    otel_ctx:attach(OtelCtx),
    temporal_sdk_grpc:request(From, Cluster, Msg, Opts, RequestInfo).
