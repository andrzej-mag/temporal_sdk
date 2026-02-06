gRPC request function.

Example:

```erlang
1> temporal_sdk_api:request('ListClusters', cluster_1, #{}, cast, #{}).
ok
2> temporal_sdk_api:request('ListClusters', cluster_1, #{}, call, #{}).
{ok,#{clusters =>
          [#{address => <<"127.0.0.1:7233">>,
             cluster_id => <<"e890d347-3100-4c73-953c-e1a5441215ab">>,
             cluster_name => <<"active">>,history_shard_count => 1,
             initial_failover_version => 1,
             http_address => <<"127.0.0.1:41771">>,
             is_connection_enabled => true}],
      next_page_token => <<>>}}
3> temporal_sdk_api:request('ListClusters', cluster_1, #{}, msg, #{}).
#Ref<0.4097329788.374603782.28828>
4> flush().
Shell got {temporal_sdk_grpc_response,#Ref<0.4097329788.374603782.28828>,
              {ok,#{clusters =>
                        [#{address => <<"127.0.0.1:7233">>,
                           cluster_id =>
                               <<"e890d347-3100-4c73-953c-e1a5441215ab">>,
                           cluster_name => <<"active">>,
                           history_shard_count => 1,
                           initial_failover_version => 1,
                           http_address => <<"127.0.0.1:41771">>,
                           is_connection_enabled => true}],
                    next_page_token => <<>>}}}
ok
```
