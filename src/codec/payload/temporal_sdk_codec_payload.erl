-module(temporal_sdk_codec_payload).

% elp:ignore W0012 W0040
-moduledoc """
Temporal payload codec behaviour module.
""".

-callback convert(
    Payload :: temporal_sdk:temporal_payload(),
    Cluster :: temporal_sdk_grpc:cluster_name(),
    RequestInfo :: temporal_sdk_grpc:request_info(),
    Opts :: term()
) ->
    {ok, ConvertedPayload :: temporal_sdk:temporal_payload()}
    | ignored
    | {error, Reason :: term()}.

%% https://github.com/temporalio/sdk-go/blob/master/converter/metadata.go
%% MetadataEncodingBinary is "binary/plain"
%% MetadataEncodingJSON is "json/plain"
%% MetadataEncodingNil is "binary/null"
%% MetadataEncodingProtoJSON is "json/protobuf"
%% MetadataEncodingProto is "binary/protobuf"
