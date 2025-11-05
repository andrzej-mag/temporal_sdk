-module(temporal_sdk_codec_payload_erl).
-behaviour(temporal_sdk_codec_payload).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    convert/4
]).

-define(ENCODING, ~"binary/erlang").

convert(
    #{data := Data, metadata := #{encoding := ?ENCODING}} = P, _Cluster, #{type := request}, Opts
) ->
    {ok, P#{data := erlang:term_to_binary(Data, Opts)}};
convert(
    #{data := Data, metadata := #{~"encoding" := ?ENCODING}} = P,
    _Cluster,
    #{type := request},
    Opts
) ->
    {ok, P#{data := erlang:term_to_binary(Data, Opts)}};
convert(
    #{data := Data, metadata := #{"encoding" := ?ENCODING}} = P, _Cluster, #{type := request}, Opts
) ->
    {ok, P#{data := erlang:term_to_binary(Data, Opts)}};
convert(#{metadata := #{encoding := _}}, _Cluster, #{type := request}, _Opts) ->
    ignored;
convert(#{metadata := #{~"encoding" := _}}, _Cluster, #{type := request}, _Opts) ->
    ignored;
convert(#{metadata := #{"encoding" := _}}, _Cluster, #{type := request}, _Opts) ->
    ignored;
convert(#{data := Data} = Payload, _Cluster, #{type := request}, Opts) ->
    Encoded = erlang:term_to_binary(Data, Opts),
    M = maps:get(metadata, Payload, #{}),
    {ok, #{data => Encoded, metadata => M#{~"encoding" => ?ENCODING}}};
convert(
    #{data := Data, metadata := #{encoding := ?ENCODING}} = Payload,
    _Cluster,
    #{type := response},
    Opts
) ->
    {ok, Payload#{data := erlang:binary_to_term(Data, Opts)}};
convert(
    #{data := Data, metadata := #{~"encoding" := ?ENCODING}} = Payload,
    _Cluster,
    #{type := response},
    Opts
) ->
    {ok, Payload#{data := erlang:binary_to_term(Data, Opts)}};
convert(
    #{data := Data, metadata := #{"encoding" := ?ENCODING}} = Payload,
    _Cluster,
    #{type := response},
    Opts
) ->
    {ok, Payload#{data := erlang:binary_to_term(Data, Opts)}};
convert(_Payload, _Cluster, _RequestInfo, _Opts) ->
    ignored.
