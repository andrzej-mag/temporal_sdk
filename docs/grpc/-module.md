gRPC request module.

gRPC request module provides unary gRPC request functionality.
Module is used by the `m:temporal_sdk_client` module.
Functions provided by the `m:temporal_sdk_api` module should be used for low-level gRPC request
handling; see `temporal_sdk_api:request/3` and `temporal_sdk_api:request/5`.

## gRPC request life cycle

```mermaid
flowchart LR
  TS@{ shape: processes, label: "Temporal Service <br> Temporal Server(s)"}
  style TS stroke-dasharray: 3 3

  subgraph REQUEST
    direction TB
    rq1[gRPC request] --> rq2[intercept request]
    rq2 --> rq3[convert request payloads]
    rq3 --> rq4[encode protobuf]
    rq4 --> rq5[compress]
    rq5 --> rq6[add headers]
    rq6 --> rq7[check message size]
  end
  REQUEST -.-> TS
  subgraph RESPONSE
    direction TB
    rp1[gRPC response] --> rp2[decompress]
    rp2 --> rp3[decode protobuf]
    rp3 --> rp4[convert response payloads]
    rp4 --> rp5[intercept response]
  end
  TS -.-> RESPONSE
```
