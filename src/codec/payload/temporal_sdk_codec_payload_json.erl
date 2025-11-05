-module(temporal_sdk_codec_payload_json).
-behaviour(temporal_sdk_codec_payload).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    convert/4
]).

-define(ENCODING, ~"json/plain").

convert(
    #{data := Data, metadata := #{encoding := ?ENCODING}} = P, _Cluster, #{type := request}, _Opts
) ->
    encode(Data, P);
convert(
    #{data := Data, metadata := #{~"encoding" := ?ENCODING}} = P,
    _Cluster,
    #{type := request},
    _Opts
) ->
    encode(Data, P);
convert(
    #{data := Data, metadata := #{"encoding" := ?ENCODING}} = P, _Cluster, #{type := request}, _Opts
) ->
    encode(Data, P);
convert(#{metadata := #{encoding := _}}, _Cluster, #{type := request}, _Opts) ->
    ignored;
convert(#{metadata := #{~"encoding" := _}}, _Cluster, #{type := request}, _Opts) ->
    ignored;
convert(#{metadata := #{"encoding" := _}}, _Cluster, #{type := request}, _Opts) ->
    ignored;
convert(#{data := Data} = Payload, _Cluster, #{type := request}, _Opts) ->
    encode(Data, Payload);
convert(
    #{data := Data, metadata := #{encoding := ?ENCODING}} = Payload,
    _Cluster,
    #{type := response},
    _Opts
) ->
    decode(Data, Payload);
convert(
    #{data := Data, metadata := #{~"encoding" := ?ENCODING}} = Payload,
    _Cluster,
    #{type := response},
    _Opts
) ->
    decode(Data, Payload);
convert(
    #{data := Data, metadata := #{"encoding" := ?ENCODING}} = Payload,
    _Cluster,
    #{type := response},
    _Opts
) ->
    decode(Data, Payload);
convert(_Payload, _Cluster, _RequestInfo, _Opts) ->
    ignored.

encode(Data, Payload) ->
    try
        M = maps:get(metadata, Payload, #{}),
        case temporal_sdk_utils_unicode:characters_to_binary(json:encode(Data)) of
            {ok, EncData} ->
                {ok, #{
                    data => EncData,
                    metadata => M#{~"encoding" => ?ENCODING}
                }};
            {error, R} ->
                {error, {json, R}}
        end
    catch
        error:Reason -> {error, {json, Reason}}
    end.

decode(Data, Payload) ->
    try
        {ok, Payload#{data := json:decode(Data)}}
    catch
        error:Reason -> {error, {json, Reason}}
    end.
