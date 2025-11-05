-module(temporal_sdk_codec_payload_binary).
-behaviour(temporal_sdk_codec_payload).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    convert/4
]).

-define(ENCODING, ~"binary/plain").

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
convert(#{data := Data} = Payload, _Cluster, #{type := request}, _Opts) when is_binary(Data) ->
    M = maps:get(metadata, Payload, #{}),
    {ok, #{data => Data, metadata => M#{~"encoding" => ?ENCODING}}};
convert(
    #{metadata := #{encoding := ?ENCODING}} = Payload, _Cluster, #{type := response}, _Opts
) ->
    {ok, Payload};
convert(
    #{metadata := #{~"encoding" := ?ENCODING}} = Payload, _Cluster, #{type := response}, _Opts
) ->
    {ok, Payload};
convert(
    #{metadata := #{"encoding" := ?ENCODING}} = Payload, _Cluster, #{type := response}, _Opts
) ->
    {ok, Payload};
convert(_Payload, _Cluster, _RequestInfo, _Opts) ->
    ignored.
