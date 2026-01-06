Retrieves the current OS statistics from the SDK OS rate limiter.

See `m:temporal_sdk_limiter#module-os-rate-limiter` for details about OS limitables.

## Example

<!-- tabs-open -->
### Elixir

```elixir
iex(1)> TemporalSdk.Node.os_stats()
%{
  :mem => 84,
  :cpu1 => 156,
  :cpu5 => 202,
  :cpu15 => 197,
  {:disk, ~c"/"} => 21,
  {:disk, ~c"/boot/efi"} => 2,
  {:disk, ~c"/dev"} => 0,
  {:disk, ~c"/dev/shm"} => 1,
  {:disk, ~c"/run"} => 1,
  {:disk, ~c"/run/lock"} => 0,
  {:disk, ~c"/run/user/1001"} => 1,
  {:disk, ~c"/tmp"} => 56
}
```

### Erlang

```erlang
1> temporal_sdk_node:os_stats().
#{mem => 84,cpu1 => 187,cpu15 => 200,cpu5 => 215,
  {disk,"/"} => 21,
  {disk,"/boot/efi"} => 2,
  {disk,"/dev"} => 0,
  {disk,"/dev/shm"} => 1,
  {disk,"/run"} => 1,
  {disk,"/run/lock"} => 0,
  {disk,"/run/user/1001"} => 1,
  {disk,"/tmp"} => 56}
```
<!-- tabs-close -->
