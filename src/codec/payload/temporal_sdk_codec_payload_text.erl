-module(temporal_sdk_codec_payload_text).
-behaviour(temporal_sdk_codec_payload).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    convert/4
]).

-define(ENCODING, ~"json/plain").

convert(#{metadata := #{encoding := ?ENCODING}} = P, _Cluster, #{type := request}, _Opts) ->
    {ok, P};
convert(#{metadata := #{~"encoding" := ?ENCODING}} = P, _Cluster, #{type := request}, _Opts) ->
    {ok, P};
convert(#{metadata := #{"encoding" := ?ENCODING}} = P, _Cluster, #{type := request}, _Opts) ->
    {ok, P};
convert(#{metadata := #{encoding := _}}, _Cluster, #{type := request}, _Opts) ->
    ignored;
convert(#{metadata := #{~"encoding" := _}}, _Cluster, #{type := request}, _Opts) ->
    ignored;
convert(#{metadata := #{"encoding" := _}}, _Cluster, #{type := request}, _Opts) ->
    ignored;
convert(#{data := Data} = Payload, _Cluster, #{type := request}, _Opts) ->
    Encoded = temporal_sdk_api:serialize_term(Data),
    M = maps:get(metadata, Payload, #{}),
    {ok, #{data => Encoded, metadata => M#{~"encoding" => ?ENCODING}}};
convert(
    #{data := _, metadata := #{encoding := ?ENCODING}} = Payload,
    _Cluster,
    #{type := response},
    _Opts
) ->
    {ok, Payload};
convert(
    #{data := _, metadata := #{~"encoding" := ?ENCODING}} = Payload,
    _Cluster,
    #{type := response},
    _Opts
) ->
    {ok, Payload};
convert(
    #{data := _, metadata := #{"encoding" := ?ENCODING}} = Payload,
    _Cluster,
    #{type := response},
    _Opts
) ->
    {ok, Payload};
convert(_Payload, _Cluster, _RequestInfo, _Opts) ->
    ignored.
