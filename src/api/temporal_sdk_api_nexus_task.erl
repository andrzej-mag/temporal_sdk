-module(temporal_sdk_api_nexus_task).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    fetch_header_sdk_data/1,
    start_operation/1,
    input/2,
    timeout/1,
    timeouts/1
]).

-include("proto.hrl").

-type start_operation() :: ?TEMPORAL_SPEC:'temporal.api.nexus.v1.StartOperationRequest'().
-export_type([start_operation/0]).

-spec fetch_header_sdk_data(temporal_sdk_nexus:task()) -> map().
fetch_header_sdk_data(#{request := #{header := #{?TASK_HEADER_KEY_SDK_DATA := Data}}}) ->
    % eqwalizer:ignore
    erlang:binary_to_term(base64:decode(Data));
fetch_header_sdk_data(#{}) ->
    #{}.

-spec start_operation(Task :: temporal_sdk_nexus:task()) -> start_operation().
start_operation(#{request := #{variant := {start_operation, SO}}}) -> SO;
start_operation(#{}) -> #{}.

input(ApiContext, Task) ->
    MsgName = 'temporal.api.nexus.v1.StartOperationRequest',
    StartOperation = start_operation(Task),
    Input = maps:get(input, StartOperation, #{data => []}),
    temporal_sdk_api:map_from_payload(ApiContext, MsgName, input, Input).

-spec timeout(Task :: temporal_sdk_nexus:task()) ->
    TimeoutMsec :: non_neg_integer() | undefined | error.
timeout(#{request := #{header := #{"operation-timeout" := T}}}) -> parse_timeout(T);
timeout(#{request := #{header := #{"request-timeout" := T}}}) -> parse_timeout(T);
timeout(#{}) -> undefined.

parse_timeout(T) ->
    case string:to_float(T) of
        {error, _} -> do_timeout(string:to_integer(T));
        TF -> do_timeout(TF)
    end.

do_timeout({T, "ms"}) -> round(T);
do_timeout({T, "s"}) -> round(T) * 1_000;
do_timeout({T, "m"}) -> round(T) * 1_000 * 60;
do_timeout(_) -> error.

-spec timeouts(Task :: temporal_sdk_nexus:task()) -> map().
timeouts(#{request := #{header := H}}) -> maps:with(["request-timeout", "operation-timeout"], H).
