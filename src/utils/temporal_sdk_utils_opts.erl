-module(temporal_sdk_utils_opts).

% elp:ignore W0012 W0040
-moduledoc false.

-include("proto.hrl").

-export([
    build/2,
    build/3
]).

-type opts_type() ::
    %% Erlang types
    any
    | atom
    | binary
    | boolean
    | float
    | function
    | integer
    | non_neg_integer
    | pos_integer
    | neg_integer
    | list
    | map
    | tuple
    | string
    | unicode
    %% Custom types
    | nested
    | undefined
    | infinity
    | time
    | limiter_limits
    %% Temporal types
    | duration
    | serializable
    | payload
    | payloads
    | mapstring_payload
    | mapstring_payloads
    | memo
    | header
    | search_attributes
    | retry_policy
    | user_metadata
    | failure.

-type opts_types() :: opts_type() | [opts_type()].

-type defaults() :: [
    {
        Key :: atom(),
        Type :: opts_types(),
        DefaultValue :: term() | '$_required' | '$_optional'
    }
    | {
        Key :: atom(),
        Type :: opts_types(),
        DefaultValue :: term() | '$_required' | '$_optional',
        TranslationOpts :: term() | '$_none'
    }
].
-export_type([defaults/0]).

-spec build(
    DefaultOpts :: defaults(),
    UserOpts :: proplists:proplist() | map()
) -> {ok, map()} | {error, {invalid_opts, map()}}.
build(DefaultOpts, UserOpts) ->
    build(DefaultOpts, UserOpts, undefined).

-spec build(
    DefaultOpts :: defaults(),
    UserOpts :: proplists:proplist() | map(),
    ApiCtx :: temporal_sdk_api:context() | undefined
) -> {ok, map()} | {error, {invalid_opts, map()}}.
build(DefaultOpts, UserOpts, ApiCtx) when is_list(UserOpts) ->
    do_build(DefaultOpts, proplists:unfold(UserOpts), ApiCtx, #{});
build(DefaultOpts, UserOpts, ApiCtx) when is_map(UserOpts) ->
    do_build(DefaultOpts, proplists:from_map(UserOpts), ApiCtx, #{}).

do_build([{Key, Type, DefaultValue} | TOpts], UserOpts, ApiCtx, Acc) ->
    do_build([{Key, Type, DefaultValue, '$_none'} | TOpts], UserOpts, ApiCtx, Acc);
do_build([{Key, Type, '$_required' = DV, TranslationOpts} | TOpts], UserOpts, AC, Acc) ->
    {Value, UO} = temporal_sdk_utils_lists:keypop(Key, UserOpts, '$_undefined'),
    case Value of
        '$_undefined' ->
            {error, {invalid_opts, #{missing_opts => Key}}};
        _ ->
            case isv(Type, Value) of
                true ->
                    do_build(TOpts, UO, AC, Acc#{Key => xlat(Type, DV, Value, TranslationOpts, AC)});
                false ->
                    {error, {invalid_opts, #{invalid_value => Value, expected_value_type => Type}}}
            end
    end;
do_build([{Key, Type, '$_optional' = DV, TranslationOpts} | TOpts], UserOpts, AC, Acc) ->
    {Value, UO} = temporal_sdk_utils_lists:keypop(Key, UserOpts, '$_undefined'),
    case Value of
        '$_undefined' ->
            do_build(TOpts, UO, AC, Acc);
        _ ->
            case isv(Type, Value) of
                true ->
                    do_build(TOpts, UO, AC, Acc#{Key => xlat(Type, DV, Value, TranslationOpts, AC)});
                false ->
                    {error, {invalid_opts, #{invalid_value => Value, expected_value_type => Type}}}
            end
    end;
do_build([{Key, nested, DefaultValue, _TranslationOpts} | TOpts], UserOpts, AC, Acc) ->
    {Value, UO} = temporal_sdk_utils_lists:keypop(Key, UserOpts, []),
    % eqwalizer:ignore
    case build(DefaultValue, Value, AC) of
        {ok, V} -> do_build(TOpts, UO, AC, Acc#{Key => V});
        Err -> Err
    end;
do_build([{Key, Type, DefaultValue, TranslationOpts} | TOpts], UserOpts, AC, Acc) ->
    {Value, UO} = temporal_sdk_utils_lists:keypop(Key, UserOpts, DefaultValue),
    case isv(Type, Value) of
        true ->
            do_build(TOpts, UO, AC, Acc#{
                Key => xlat(Type, DefaultValue, Value, TranslationOpts, AC)
            });
        false ->
            {error, {invalid_opts, #{invalid_value => Value, expected_value_type => Type}}}
    end;
do_build([], [], _ApiCtx, Acc) ->
    {ok, Acc};
do_build([], UserOpts, _ApiCtx, _Acc) ->
    {error, {invalid_opts, UserOpts}}.

%% Erlang types
isv(any, _V) ->
    true;
isv(atom, V) when is_atom(V) -> true;
isv(binary, V) when is_binary(V) -> true;
isv(boolean, V) when is_boolean(V) -> true;
isv(float, V) when is_float(V) -> true;
isv(function, V) when is_function(V) -> true;
isv(function, {M, F}) when is_atom(M), is_atom(F) -> true;
isv(function, {M, F, _A}) when is_atom(M), is_atom(F) -> true;
isv(integer, V) when is_integer(V) -> true;
isv(non_neg_integer, V) when is_integer(V), V >= 0 -> true;
isv(pos_integer, V) when is_integer(V), V >= 1 -> true;
isv(neg_integer, V) when is_integer(V), V < 0 -> true;
isv(list, V) when is_list(V) -> true;
isv(map, V) when is_map(V) -> true;
isv(tuple, V) when is_tuple(V) -> true;
isv(string, V) when is_list(V) -> io_lib:char_list(V);
isv(unicode, V) when is_list(V); is_binary(V) -> true;
%% Custom types
isv(undefined, undefined) ->
    true;
isv(infinity, infinity) ->
    true;
isv(time, V) when is_integer(V), V >= 0 -> true;
isv(time, {V, U}) when is_integer(V), V >= 0, is_atom(U) -> true;
isv(limiter_limits, {V1, V2}) when is_integer(V1), V1 > 0, is_integer(V2), V2 > 0 -> true;
%% Temporal types
isv(duration, V) when is_integer(V), V >= 0 -> true;
isv(duration, {V, U}) when is_number(V), V >= 0, is_atom(U) -> true;
isv(serializable, _V) ->
    true;
isv(payload, _V) ->
    true;
isv(payloads, V) when is_list(V) -> true;
isv(mapstring_payload, V) when is_map(V) -> true;
isv(mapstring_payloads, V) when is_map(V) -> true;
isv(memo, V) when is_map(V) -> true;
isv(header, V) when is_map(V), not is_map_key(?TASK_HEADER_KEY_SDK_DATA, V) -> true;
isv(search_attributes, V) when is_map(V) -> true;
isv(retry_policy, V) when is_map(V) -> true;
isv(user_metadata, V) when is_map(V) ->
    case map_size(maps:without([summary, details], V)) of
        0 -> true;
        _ -> false
    end;
isv(failure, V) when is_map(V); is_list(V) -> true;
%% Types list
isv(Types, V) when is_list(Types) -> lists:any(fun(T) -> isv(T, V) end, Types);
%% Invalid types
isv(_, _) ->
    false.

%% Erlang types
xlat(map, DV, V, merge, _ApiContext) ->
    maps:merge(DV, V);
%% Custom types
xlat(time, _DV, V, '$_none', _ApiContext) when is_integer(V) -> V;
xlat(time, _DV, {V, U}, '$_none', _ApiContext) ->
    temporal_sdk_utils_time:convert_to_msec(V, U);
%% Temporal types
xlat(duration, _DV, V, '$_none', _ApiContext) when is_integer(V) ->
    temporal_sdk_utils_time:msec_to_protobuf(V);
xlat(duration, _DV, {V, U}, '$_none', _ApiContext) ->
    temporal_sdk_utils_time:msec_to_protobuf(temporal_sdk_utils_time:convert_to_msec(V, U));
xlat(serializable, _DV, V, {MsgName, Key}, ApiContext) ->
    temporal_sdk_api:serialize(ApiContext, MsgName, Key, V);
xlat(payload, _DV, V, {MsgName, Key}, ApiContext) ->
    temporal_sdk_api:map_to_payload(ApiContext, MsgName, Key, V);
xlat(payloads, _DV, V, {MsgName, Key}, ApiContext) ->
    temporal_sdk_api:map_to_payloads(ApiContext, MsgName, Key, V);
xlat(mapstring_payload, _DV, V, {MsgName, Key}, ApiContext) ->
    temporal_sdk_api:map_to_mapstring_payload(ApiContext, MsgName, Key, V);
xlat(mapstring_payloads, _DV, V, {MsgName, Key}, ApiContext) ->
    temporal_sdk_api:map_to_mapstring_payloads(ApiContext, MsgName, Key, V);
xlat(memo, _DV, V, {MsgName, Key}, ApiContext) ->
    #{fields => temporal_sdk_api:map_to_mapstring_payload(ApiContext, MsgName, Key, V)};
xlat(header, _DV, V, {MsgName, Key}, ApiContext) ->
    #{fields => temporal_sdk_api:map_to_mapstring_payload(ApiContext, MsgName, Key, V)};
xlat(search_attributes, _DV, V, {MsgName, Key}, ApiContext) ->
    #{indexed_fields => temporal_sdk_api:map_to_mapstring_payload(ApiContext, MsgName, Key, V)};
xlat(retry_policy, _DV, V, '$_none', _ApiContext) ->
    temporal_sdk_api_common:retry_policy(V);
xlat(user_metadata, _DV, V, {MsgName, Key}, ApiContext) ->
    R1 =
        case V of
            #{summary := S} ->
                #{
                    summary => temporal_sdk_api:map_to_payload(
                        ApiContext, MsgName, [Key, summary], S
                    )
                };
            #{} ->
                #{}
        end,
    case V of
        #{details := D} ->
            R1#{details => temporal_sdk_api:map_to_payload(ApiContext, MsgName, [Key, details], D)};
        #{} ->
            R1
    end;
xlat(failure, _DV, V, '$_none', ApiContext) ->
    case temporal_sdk_api_failure:build(ApiContext, V) of
        {ok, F} ->
            F;
        Err ->
            {ok, F} = temporal_sdk_api_failure:build(ApiContext, #{
                source => error, message => Err, stack_trace => "temporal_sdk_api_failure:build/2"
            }),
            F
    end;
xlat([Type | TTypes], DV, V, TranslationOpts, ApiContext) ->
    xlat(TTypes, DV, xlat(Type, DV, V, TranslationOpts, ApiContext), TranslationOpts, ApiContext);
xlat(_Type, _DV, V, _TranslationOpts, _ApiContext) ->
    V.
