-module(temporal_sdk_api_failure).

% elp:ignore W0012 W0040
-moduledoc false.

-export([
    build/2,
    from_temporal/2
]).

-include("proto.hrl").

-spec build(
    ApiContext :: temporal_sdk_api:context(),
    ApplicationFailure ::
        temporal_sdk:application_failure() | temporal_sdk:user_application_failure()
) ->
    {ok, ?TEMPORAL_SPEC:'temporal.api.failure.v1.Failure'()}
    | {error, {invalid_opts, map()}}.
build(ApiContext, ApplicationFailure) ->
    DefaultFailure = [
        %% Failure
        {source, serializable, '$_optional', {'temporal.api.failure.v1.Failure', source}},
        {message, serializable, '$_optional', {'temporal.api.failure.v1.Failure', message}},
        {stack_trace, serializable, '$_optional', {'temporal.api.failure.v1.Failure', stack_trace}},
        {encoded_attributes, payload, '$_optional',
            {'temporal.api.failure.v1.Failure', encoded_attributes}},
        %% ApplicationFailureInfo
        {type, unicode, '$_optional'},
        {non_retryable, boolean, '$_optional'},
        {details, payloads, '$_optional',
            {'temporal.api.failure.v1.ApplicationFailureInfo', details}},
        {next_retry_delay, duration, '$_optional'}
    ],
    case temporal_sdk_utils_opts:build(DefaultFailure, ApplicationFailure, ApiContext) of
        {ok, AF} ->
            AFI = maps:with([type, non_retryable, details, next_retry_delay], AF),
            F = maps:without([type, non_retryable, details, next_retry_delay], AF),
            {ok, put_failure_info(ApiContext, F, AFI)};
        Err ->
            Err
    end.

put_failure_info(#{worker_type := workflow}, Failure, FI) when map_size(FI) =:= 0 ->
    Failure;
put_failure_info(#{}, Failure, FailureInfo) ->
    Failure#{failure_info => {application_failure_info, FailureInfo}}.

-spec from_temporal(
    ApiCtx :: temporal_sdk_api:context(),
    TemporalFailure :: ?TEMPORAL_SPEC:'temporal.api.failure.v1.Failure'()
) ->
    temporal_sdk:failure_from_temporal().
from_temporal(ApiCtx, #{failure_info := FI} = F) ->
    Failure = do_failure(maps:with([message, source, stack_trace], F), ApiCtx),
    Failure#{failure_info => do_failure_info(FI, ApiCtx)};
from_temporal(ApiCtx, F) ->
    do_failure(maps:with([message, source, stack_trace], F), ApiCtx).

do_failure(#{encoded_attributes := EA} = F, ApiCtx) ->
    MN = 'temporal.api.failure.v1.Failure',
    F#{
        encoded_attributes :=
            temporal_sdk_api:map_from_payload(ApiCtx, MN, encoded_attributes, EA)
    };
do_failure(F, _ApiCtx) ->
    F.

do_failure_info({application_failure_info, AFI}, ApiCtx) ->
    MN = 'temporal.api.failure.v1.ApplicationFailureInfo',
    AFI1 = maps:with([type, non_retryable], AFI),
    AFI2 =
        case AFI of
            #{details := D} ->
                AFI1#{details => temporal_sdk_api:map_from_payloads(ApiCtx, MN, details, D)};
            #{} ->
                AFI1
        end,
    AFI3 =
        case AFI of
            #{next_retry_delay := NRD} ->
                AFI2#{next_retry_delay => temporal_sdk_utils_time:protobuf_to_msec(NRD)};
            #{} ->
                AFI2
        end,
    {application_failure_info, AFI3};
do_failure_info(FI, _ApiCtx) ->
    FI.
