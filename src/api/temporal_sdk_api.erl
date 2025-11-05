-module(temporal_sdk_api).

% elp:ignore W0012 W0040
-moduledoc """
Temporal API helpers.
""".

%% public SDK functions:
-export([
    request/3,
    request/5,
    from_json/3,
    from_json/4,
    to_json/3,
    to_json/4
]).
%% public internal functions:
-export([
    request/4,
    map_from_payload/4,
    map_from_payloads/4,
    map_from_mapstring_payload/4,
    map_from_mapstring_payloads/4,
    map_to_mapstring_payload/4,
    map_to_mapstring_payloads/4,
    map_to_payloads/4,
    map_to_payload/4,
    put_id/4,
    put_identity/3,
    serialize/4,
    serialize_term/1
]).
%% callback functions referenced in `temporal_sdk_client:opts` or `temporal_sdk_worker:opts`:
-export([
    id/4,
    identity/3,
    is_retryable/3,
    from_payload_mapper/5,
    to_payload_mapper/5,
    serializer/4,
    temporal_name_to_erlang/2,
    session_task_queue_name/3
]).

-include("proto.hrl").

-type temporal_service() :: temporal_sdk_proto:service().
-export_type([temporal_service/0]).

-type context() :: #{
    cluster := temporal_sdk_cluster:cluster_name(),
    enable_single_distributed_workflow_execution => boolean() | undefined,
    workflow_scope => temporal_sdk_node:scope_config() | scope() | undefined,
    client_opts => temporal_sdk_client:opts(),
    worker_opts => temporal_sdk_worker:opts(),
    task_opts => activity_task_opts() | workflow_task_opts(),
    worker_type => temporal_sdk_worker:worker_type(),
    worker_identity => temporal_sdk:serializable(),
    limiter_counters => [[counters:counters_ref()]],
    execution_module => module()
}.
-export_type([context/0]).

-type scope() :: #{
    scope := temporal_sdk_cluster:cluster_name(),
    partitions_size := pos_integer(),
    partition_id => non_neg_integer(),
    ets_scope_id => atom(),
    pg_scope_id => atom()
}.
-export_type([scope/0]).

-type activity_task_opts() :: #{
    token := unicode:chardata() | undefined,
    index_key => temporal_sdk_workflow:activity()
}.

-type workflow_task_opts() :: #{
    token := unicode:chardata() | undefined,
    next_page_token => unicode:chardata(),
    workflow_type := unicode:chardata(),
    workflow_id := unicode:chardata(),
    run_id := unicode:chardata(),
    sticky_attributes := ?TEMPORAL_SPEC:'temporal.api.taskqueue.v1.StickyExecutionAttributes'()
}.

-define(LONGPOLL_SERVICES, [
    'PollActivityTaskQueue',
    'PollWorkflowTaskQueue',
    'PollWorkflowExecutionUpdate',
    'PollNexusTaskQueue'
]).

%% -------------------------------------------------------------------------------------------------
%% public SDK functions

-spec request(
    ServiceName :: temporal_service(),
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Msg :: temporal_sdk_client:msg()
) -> Result :: temporal_sdk_client:call_result().
request(ServiceName, Cluster, Msg) ->
    request(ServiceName, Cluster, Msg, call, #{}).

-spec request
    (
        ServiceName :: temporal_service(),
        Cluster :: temporal_sdk_cluster:cluster_name(),
        Msg :: temporal_sdk_client:msg(),
        ReqType,
        EnvGrpcOpts :: temporal_sdk_client:grpc_opts()
    ) ->
        Result :: temporal_sdk_client:call_result()
    when
        ReqType :: call_formatted;
    (
        ServiceName :: temporal_service(),
        Cluster :: temporal_sdk_cluster:cluster_name(),
        Msg :: temporal_sdk_client:msg(),
        ReqType,
        EnvGrpcOpts :: temporal_sdk_client:grpc_opts()
    ) ->
        Result :: temporal_sdk_client:call_result()
    when
        ReqType :: call;
    (
        ServiceName :: temporal_service(),
        Cluster :: temporal_sdk_cluster:cluster_name(),
        Msg :: temporal_sdk_client:msg(),
        ReqType,
        EnvGrpcOpts :: temporal_sdk_client:grpc_opts()
    ) ->
        Result :: temporal_sdk_client:cast_result()
    when
        ReqType :: cast;
    (
        ServiceName :: temporal_service(),
        Cluster :: temporal_sdk_cluster:cluster_name(),
        Msg :: temporal_sdk_client:msg(),
        ReqType,
        EnvGrpcOpts :: temporal_sdk_client:grpc_opts()
    ) ->
        Result :: temporal_sdk_client:msg_result()
    when
        ReqType :: msg.
request(ServiceName, Cluster, Msg, call_formatted, EnvGrpcOpts) ->
    request(ServiceName, Cluster, Msg, call, EnvGrpcOpts);
request(ServiceName, Cluster, Msg, ReqType, EnvGrpcOpts) ->
    case grpc_opts_from_env(ServiceName, Cluster, EnvGrpcOpts) of
        {ok, GrpcOpts} -> do_request(ServiceName, Cluster, Msg, ReqType, GrpcOpts);
        Err -> Err
    end.

-spec from_json(
    MsgName :: temporal_sdk_client:msg_name(),
    Cluster :: temporal_sdk_cluster:cluster_name(),
    JsonBin :: binary()
) ->
    {ok, Msg :: temporal_sdk_client:msg()} | {error, Reason :: term()}.
from_json(MsgName, Cluster, JsonBin) -> from_json(MsgName, Cluster, JsonBin, #{}).

-spec from_json(
    MsgName :: temporal_sdk_client:msg_name(),
    Cluster :: temporal_sdk_cluster:cluster_name(),
    JsonBin :: binary(),
    EnvGrpcOpts :: temporal_sdk_client:grpc_opts()
) ->
    {ok, Msg :: temporal_sdk_client:msg()} | {error, Reason :: term()}.
from_json(MsgName, Cluster, JsonBin, EnvGrpcOpts) ->
    maybe
        {ok, GrpcOpts} ?= grpc_opts_from_env(undefined, Cluster, EnvGrpcOpts),
        {ok, Json} ?= temporal_sdk_utils_json:decode(JsonBin),
        {ok, Msg} ?= temporal_sdk_grpc:from_json(Json, MsgName, GrpcOpts),
        temporal_sdk_grpc:convert_response(Cluster, Msg, MsgName, GrpcOpts)
    else
        Err -> Err
    end.

-spec to_json(
    MsgName :: temporal_sdk_client:msg_name(),
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Message :: temporal_sdk_client:msg()
) ->
    {ok, Json :: iodata()} | {error, Reason :: term()}.
to_json(MsgName, Cluster, Message) ->
    to_json(MsgName, Cluster, Message, #{}).

-spec to_json(
    MsgName :: temporal_sdk_client:msg_name(),
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Message :: temporal_sdk_client:msg(),
    EnvGrpcOpts :: temporal_sdk_client:grpc_opts()
) ->
    {ok, Json :: iodata()} | {error, Reason :: term()}.
to_json(MsgName, Cluster, Message, EnvGrpcOpts) ->
    maybe
        {ok, GrpcOpts} ?= grpc_opts_from_env(undefined, Cluster, EnvGrpcOpts),
        {ok, Msg} ?= temporal_sdk_grpc:convert_request(Cluster, Message, MsgName, GrpcOpts),
        {ok, Json} ?= temporal_sdk_grpc:to_json(Msg, MsgName, GrpcOpts),
        temporal_sdk_utils_json:encode(Json)
    else
        Err -> Err
    end.

%% -------------------------------------------------------------------------------------------------
%% public internal functions

-doc false.
-spec request
    (
        ServiceName :: temporal_service(),
        ApiContext :: temporal_sdk_api:context(),
        Msg :: temporal_sdk_client:msg(),
        ReqType
    ) ->
        Result :: temporal_sdk_client:call_result()
    when
        ReqType :: call_formatted;
    (
        ServiceName :: temporal_service(),
        ApiContext :: temporal_sdk_api:context(),
        Msg :: temporal_sdk_client:msg(),
        ReqType
    ) ->
        Result :: temporal_sdk_client:call_result()
    when
        ReqType :: call;
    (
        ServiceName :: temporal_service(),
        ApiContext :: temporal_sdk_api:context(),
        Msg :: temporal_sdk_client:msg(),
        ReqType
    ) ->
        Result :: temporal_sdk_client:cast_result()
    when
        ReqType :: cast;
    (
        ServiceName :: temporal_service(),
        ApiContext :: temporal_sdk_api:context(),
        Msg :: temporal_sdk_client:msg(),
        ReqType
    ) ->
        Result :: temporal_sdk_client:msg_result()
    when
        ReqType :: msg.
request(ServiceName, ApiContext, Msg, call_formatted) ->
    request(ServiceName, ApiContext, Msg, call);
request(ServiceName, ApiContext, Msg, ReqType) ->
    #{
        cluster := Cluster,
        client_opts := #{grpc_opts := GrpcOpts, grpc_opts_longpoll := GrpcOptsLongPoll}
    } = ApiContext,
    case is_longpoll_request(ServiceName) of
        false -> do_request(ServiceName, Cluster, Msg, ReqType, GrpcOpts);
        true -> do_request(ServiceName, Cluster, Msg, ReqType, GrpcOptsLongPoll)
    end.

-doc false.
-spec map_from_payload(
    ApiContext :: temporal_sdk_api:context(),
    MsgName :: temporal_sdk_client:msg_name(),
    Key :: term(),
    Payload :: temporal_sdk:temporal_payload()
) -> temporal_sdk:term_from_payload().
map_from_payload(
    #{cluster := Cluster, client_opts := #{helpers := #{from_payload_mapper := MapperFn}}},
    MsgName,
    Key,
    Payload
) ->
    MapperFn(Cluster, MsgName, Key, 1, Payload).

-doc false.
-spec map_from_payloads(
    ApiContext :: temporal_sdk_api:context(),
    MsgName :: temporal_sdk_client:msg_name(),
    Key :: term(),
    Payloads :: temporal_sdk:temporal_payloads()
) -> temporal_sdk:term_from_payloads().
map_from_payloads(
    #{cluster := Cluster, client_opts := #{helpers := #{from_payload_mapper := MapperFn}}},
    MsgName,
    Key,
    #{payloads := _} = Payloads
) ->
    from_payloads_mapper(Cluster, MsgName, Key, Payloads, MapperFn);
map_from_payloads(
    _ApiContext,
    _MsgName,
    _Key,
    #{} = Payloads
) when map_size(Payloads) =:= 0 ->
    [].

-doc false.
-spec map_from_mapstring_payload(
    ApiContext :: temporal_sdk_api:context(),
    MsgName :: temporal_sdk_client:msg_name(),
    Key :: term(),
    MapstringPayload :: temporal_sdk:temporal_mapstring_payload()
) -> temporal_sdk:term_from_mapstring_payload().
map_from_mapstring_payload(
    #{cluster := Cluster, client_opts := #{helpers := #{from_payload_mapper := MapperFn}}},
    MsgName,
    Key,
    MapstringPayload
) when is_map(MapstringPayload) ->
    Fn = fun(K, V, Acc) -> Acc#{K => MapperFn(Cluster, MsgName, Key, 1, V)} end,
    maps:fold(Fn, #{}, MapstringPayload).

-doc false.
-spec map_from_mapstring_payloads(
    ApiContext :: temporal_sdk_api:context(),
    MsgName :: temporal_sdk_client:msg_name(),
    Key :: term(),
    MapstringPayloads :: temporal_sdk:temporal_mapstring_payloads()
) -> temporal_sdk:term_from_mapstring_payloads().
map_from_mapstring_payloads(
    #{cluster := Cluster, client_opts := #{helpers := #{from_payload_mapper := MapperFn}}},
    MsgName,
    Key,
    MapstringPayloads
) when is_map(MapstringPayloads) ->
    Fn = fun(K, V, Acc) -> Acc#{K => from_payloads_mapper(Cluster, MsgName, Key, V, MapperFn)} end,
    maps:fold(Fn, #{}, MapstringPayloads).

-doc false.
-spec map_to_mapstring_payload(
    ApiContext :: temporal_sdk_api:context(),
    MsgName :: temporal_sdk_client:msg_name(),
    Key :: term(),
    TermToMapstringPayload :: temporal_sdk:term_to_mapstring_payload()
) -> MapstringPayload :: temporal_sdk:temporal_mapstring_payload().
map_to_mapstring_payload(
    #{cluster := Cluster, client_opts := #{helpers := #{to_payload_mapper := MapperFn}}},
    MsgName,
    Key,
    TermToMapstringPayload
) ->
    Fn = fun
        (K, V, Acc) when is_atom(K) ->
            Acc#{atom_to_binary(K) => MapperFn(Cluster, MsgName, Key, 1, V)};
        (K, V, Acc) when is_list(K); is_binary(K) ->
            Acc#{K => MapperFn(Cluster, MsgName, Key, 1, V)}
    end,
    maps:fold(Fn, #{}, TermToMapstringPayload).

-doc false.
-spec map_to_mapstring_payloads(
    ApiContext :: temporal_sdk_api:context(),
    MsgName :: temporal_sdk_client:msg_name(),
    Key :: term(),
    TermToMapstringPayloads :: temporal_sdk:term_to_mapstring_payloads()
) -> MapstringPayloads :: temporal_sdk:temporal_mapstring_payloads().
map_to_mapstring_payloads(
    #{cluster := Cluster, client_opts := #{helpers := #{to_payload_mapper := MapperFn}}},
    MsgName,
    Key,
    TermToMapstringPayloads
) when is_map(TermToMapstringPayloads) ->
    Fn = fun
        (K, V, Acc) when is_atom(K) ->
            Acc#{atom_to_binary(K) => to_payloads_mapper(Cluster, MsgName, Key, V, MapperFn)};
        (K, V, Acc) when is_list(K); is_binary(K) ->
            Acc#{K => to_payloads_mapper(Cluster, MsgName, Key, V, MapperFn)}
    end,
    maps:fold(Fn, #{}, TermToMapstringPayloads).

-doc false.
-spec map_to_payloads(
    ApiContext :: temporal_sdk_api:context(),
    MsgName :: temporal_sdk_client:msg_name(),
    Key :: term(),
    TermToPayloads :: temporal_sdk:term_to_payloads()
) -> Payloads :: temporal_sdk:temporal_payloads().
map_to_payloads(
    #{cluster := Cluster, client_opts := #{helpers := #{to_payload_mapper := MapperFn}}},
    MsgName,
    Key,
    TermToPayloads
) when is_list(TermToPayloads) ->
    to_payloads_mapper(Cluster, MsgName, Key, TermToPayloads, MapperFn).

-doc false.
-spec map_to_payload(
    ApiContext :: temporal_sdk_api:context(),
    MsgName :: temporal_sdk_client:msg_name(),
    Key :: term(),
    TermToPayload :: temporal_sdk:term_to_payload()
) -> Payloads :: temporal_sdk:temporal_payload().
map_to_payload(
    #{cluster := Cluster, client_opts := #{helpers := #{to_payload_mapper := MapperFn}}},
    MsgName,
    Key,
    TermToPayload
) ->
    MapperFn(Cluster, MsgName, Key, 1, TermToPayload).

-doc false.
-spec put_id(
    ApiContext :: temporal_sdk_api:context(),
    MsgName :: temporal_sdk_client:msg_name(),
    IdKey :: term(),
    Msg :: map()
) -> MsgWithId :: map().
put_id(#{cluster := Cluster, client_opts := #{helpers := #{id := IdFn}}}, MsgName, IdKey, Msg) ->
    case Msg of
        #{IdKey := _} -> Msg;
        #{} -> Msg#{IdKey => IdFn(Cluster, MsgName, IdKey, Msg)}
    end.

-doc false.
-spec put_identity(
    ApiContext :: temporal_sdk_api:context(),
    MsgName :: temporal_sdk_client:msg_name(),
    Msg :: map()
) -> MsgWithIdentity :: map().
put_identity(_ApiContext, _MsgName, #{identity := _} = Msg) ->
    Msg;
put_identity(
    #{
        cluster := Cluster,
        client_opts := #{helpers := #{identity := IdentityFn}},
        worker_identity := WorkerIdentity
    },
    MsgName,
    Msg
) ->
    Msg#{identity => IdentityFn(Cluster, MsgName, WorkerIdentity)}.

-doc false.
-spec serialize(
    ApiContext :: temporal_sdk_api:context(),
    MsgName :: temporal_sdk_client:msg_name() | 'temporal.api.command.v1.*' | atom(),
    Key :: term(),
    Term :: temporal_sdk:serializable()
) -> SerializedTerm :: unicode:chardata().
serialize(
    #{cluster := Cluster, client_opts := #{helpers := #{serializer := SerializerFn}}},
    MsgName,
    Key,
    Term
) ->
    SerializerFn(Cluster, MsgName, Key, Term).

-doc false.
-spec serialize_term(Term :: term()) -> string().
serialize_term(Term) ->
    case io_lib:char_list(Term) of
        true -> Term;
        false -> temporal_sdk_utils_unicode:characters_to_list1(io_lib:format("~0tkp", [Term]))
    end.

%% -------------------------------------------------------------------------------------------------
%% callback functions referenced in `temporal_sdk_client:opts` and `temporal_sdk_worker:opts`

-spec id(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    MsgName :: temporal_sdk_client:msg_name(),
    IdKey :: term(),
    Msg :: map()
) -> unicode:chardata().
id(Cluster, _MsgName, _IdKey, #{activity_type := #{name := Name}}) ->
    temporal_sdk_utils_path:string_path([Cluster, Name, temporal_sdk_utils:uuid4()], "-");
id(Cluster, _MsgName, _IdKey, #{workflow_type := #{name := Name}}) ->
    temporal_sdk_utils_path:string_path([Cluster, Name, temporal_sdk_utils:uuid4()], "-");
id(Cluster, _MsgName, _IdKey, _Msg) ->
    temporal_sdk_utils_path:string_path([Cluster, temporal_sdk_utils:uuid4()], "-").

-spec identity(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    MsgName :: temporal_sdk_client:msg_name(),
    Identity :: temporal_sdk:serializable()
) -> unicode:chardata().
identity(Cluster, _MsgName, Identity) when is_list(Identity) ->
    {ok, Hostname} = inet:gethostname(),
    temporal_sdk_utils_path:string_path([Hostname, node(), Cluster] ++ Identity, "/");
identity(Cluster, MsgName, Identity) ->
    identity(Cluster, MsgName, [Identity]).

-spec is_retryable(
    Result :: temporal_sdk_grpc:result(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    Attempt :: pos_integer()
) -> boolean().
is_retryable({error, {no_connection_available, _}}, _RequestInfo, _Attempt) ->
    true;
is_retryable(_Result, _RequestInfo, _Attempt) ->
    false.

-spec from_payload_mapper(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    MsgName :: temporal_sdk_client:msg_name(),
    Key :: term(),
    Position :: pos_integer(),
    Data :: temporal_sdk:temporal_payload()
) -> Arg :: temporal_sdk:term_from_payload().
from_payload_mapper(_Cluster, _MsgName, _Key, _Position, #{data := Data}) -> Data.

-spec to_payload_mapper(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    MsgName :: temporal_sdk_client:msg_name(),
    Key :: term(),
    Position :: pos_integer(),
    Data :: temporal_sdk:term_to_payload()
) -> Payload :: temporal_sdk:temporal_payload().
to_payload_mapper(_Cluster, _MsgName, _Key, _Position, Data) -> #{data => Data}.

-spec serializer(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    MsgName :: temporal_sdk_client:msg_name(),
    Key :: term(),
    Term :: temporal_sdk:serializable()
) -> unicode:chardata().
serializer(_Cluster, _MsgName, _Key, Term) ->
    serialize_term(Term).

-spec temporal_name_to_erlang(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    TemporalTypeName :: unicode:chardata()
) -> {ok, module()} | {error, {Reason :: string(), Details :: map()}}.
temporal_name_to_erlang(Cluster, TemporalTypeName) ->
    % eqwalizer:ignore
    N1 = string:lowercase(TemporalTypeName),
    N2 = string:replace(N1, "-", "_", all),
    % eqwalizer:ignore
    N3 = string:replace(N2, ".", "_", all),
    case temporal_sdk_utils_unicode:characters_to_binary(N3) of
        {ok, Name} ->
            try
                {ok, binary_to_existing_atom(Name)}
            catch
                error:badarg:_Stacktrace ->
                    {error,
                        {"Undefined Erlang module for Temporal activity or workflow type name.", #{
                            cluster => Cluster,
                            temporal_type_name => TemporalTypeName,
                            erlang_name => Name
                        }}}
            end;
        Err ->
            {error,
                {"Failed to convert Temporal activity or workflow type name to Erlang module.", #{
                    error => Err,
                    cluster => Cluster,
                    temporal_type_name => TemporalTypeName
                }}}
    end.

-spec session_task_queue_name(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    Namespace :: unicode:chardata(),
    ParentTaskQueueName :: unicode:chardata()
) -> unicode:chardata().
session_task_queue_name(Cluster, Namespace, ParentTQ) ->
    {ok, Hostname} = inet:gethostname(),
    temporal_sdk_utils_path:string_path([Hostname, node(), Cluster, Namespace, ParentTQ]).

%% -------------------------------------------------------------------------------------------------
%% private

-spec grpc_opts_from_env(
    ServiceName :: temporal_service() | undefined,
    Cluster :: temporal_sdk_cluster:cluster_name(),
    EnvGrpcOpts :: temporal_sdk_client:grpc_opts()
) ->
    {ok, temporal_sdk_client:grpc_opts()}
    | {error, invalid_cluster}
    | {error, {invalid_opts, Reason :: map()}}.
grpc_opts_from_env(ServiceName, Cluster, EnvGrpcOpts) ->
    maybe
        % eqwalizer:ignore
        ok ?= temporal_sdk_grpc_opts:check_opts(EnvGrpcOpts),
        {ok, #{grpc_opts := Opts, grpc_opts_longpoll := OptsLongPoll}} ?=
            % eqwalizer:ignore
            temporal_sdk_client_opts:get_opts(Cluster),
        case is_longpoll_request(ServiceName) of
            false -> {ok, maps:merge(Opts, EnvGrpcOpts)};
            true -> {ok, maps:merge(OptsLongPoll, EnvGrpcOpts)}
        end
    end.

is_longpoll_request(ServiceName) -> lists:member(ServiceName, ?LONGPOLL_SERVICES).

do_request(ServiceName, Cluster, Msg, ReqType, GrpcOpts) ->
    ServiceInfo = temporal_sdk_proto:info(ServiceName),
    temporal_sdk_client:request(Cluster, Msg, ReqType, GrpcOpts, ServiceInfo#{type => request}).

-spec to_payloads_mapper(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    MsgName :: temporal_sdk_client:msg_name(),
    Key :: term(),
    Args :: temporal_sdk:term_to_payloads(),
    MapperFn :: temporal_sdk_client:to_payload_mapper()
) -> Payloads :: temporal_sdk:temporal_payloads().
to_payloads_mapper(Cluster, MsgName, Key, Args, MapperFn) when is_list(Args) ->
    Fn = fun(Payload, Position) ->
        {MapperFn(Cluster, MsgName, Key, Position, Payload), Position + 1}
    end,
    {MappedPayloads, _Acc} = lists:mapfoldl(Fn, 1, Args),
    #{payloads => MappedPayloads}.

-spec from_payloads_mapper(
    Cluster :: temporal_sdk_cluster:cluster_name(),
    MsgName :: temporal_sdk_client:msg_name(),
    Key :: term(),
    Payloads :: temporal_sdk:temporal_payloads(),
    MapperFn :: temporal_sdk_client:from_payload_mapper()
) -> Args :: temporal_sdk:term_from_payloads().
from_payloads_mapper(Cluster, MsgName, Key, #{payloads := Payloads}, MapperFn) when
    is_list(Payloads)
->
    Fn = fun(Payload, Position) ->
        {MapperFn(Cluster, MsgName, Key, Position, Payload), Position + 1}
    end,
    {MappedPayloads, _Acc} = lists:mapfoldl(Fn, 1, Payloads),
    MappedPayloads.
