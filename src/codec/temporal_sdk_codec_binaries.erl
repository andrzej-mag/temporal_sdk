-module(temporal_sdk_codec_binaries).
-behaviour(temporal_sdk_grpc_codec).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    encode_msg/3,
    decode_msg/4,
    from_json/3,
    to_json/3,
    cast/1
]).

encode_msg(
    Msg,
    #{input := Input, service_fqname := 'temporal.api.workflowservice.v1.WorkflowService'},
    Opts
) ->
    temporal_sdk_codec:encode_msg(
        Msg, Input, Opts, temporal_sdk_proto_service_workflow_binaries
    );
encode_msg(
    Msg,
    #{input := Input, service_fqname := 'temporal.api.operatorservice.v1.OperatorService'},
    Opts
) ->
    temporal_sdk_codec:encode_msg(
        Msg, Input, Opts, temporal_sdk_proto_service_operator_binaries
    ).

decode_msg(
    Msg,
    #{output := Output, service_fqname := 'temporal.api.workflowservice.v1.WorkflowService'},
    HContentType,
    Opts
) ->
    temporal_sdk_codec:decode_msg(
        Msg, Output, HContentType, Opts, temporal_sdk_proto_service_workflow_binaries
    );
decode_msg(
    Msg,
    #{output := Output, service_fqname := 'temporal.api.operatorservice.v1.OperatorService'},
    HContentType,
    Opts
) ->
    temporal_sdk_codec:decode_msg(
        Msg, Output, HContentType, Opts, temporal_sdk_proto_service_operator_binaries
    ).

from_json(Json, MsgName, Opts) ->
    temporal_sdk_codec:from_json(Json, MsgName, Opts, temporal_sdk_proto_service_workflow_binaries).

to_json(Msg, MsgName, Opts) ->
    temporal_sdk_codec:to_json(Msg, MsgName, Opts, temporal_sdk_proto_service_workflow_binaries).

-spec cast(Term :: atom() | binary() | string()) -> EncodedTerm :: binary() | no_return().
cast(Term) when is_atom(Term) -> atom_to_binary(Term);
cast(Term) when is_binary(Term) -> Term;
cast(Term) ->
    case io_lib:char_list(Term) of
        true -> binary:list_to_bin(Term);
        false -> erlang:error("Invalid type. Allowed types: atom(), binary(), string()", [Term])
    end.
