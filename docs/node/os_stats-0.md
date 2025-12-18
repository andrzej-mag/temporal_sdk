Retrieves the current OS statistics from the SDK OS rate limiter.

Function provides information about current OS resource usage:

- `:mem`/`mem` memory usage as a percentage calculated using code snippet below.
  Requires `m:memsup`.

```erlang
case memsup:get_memory_data() of
    {0, 0, _} -> -1;
    {Total, Allocated, _Worst} -> round(Allocated / Total * 100)
end;
```

- `:cpu1`/`cpu1` average system load over the last minute retrieved from `cpu_sup:avg1/0`.
  Returns `-1` if `m:cpu_sup` is not available.
  Requires `m:cpu_sup`.

- `:cpu5`/`cpu5` average system load over the last five minutes retrieved from `cpu_sup:avg5/0`.
  Returns `-1` if `m:cpu_sup` is not available.
  Requires `m:cpu_sup`.

- `:cpu15`/`cpu15` average system load over the last 15 minutes retrieved from `cpu_sup:avg15/0`.
  Returns `-1` if `m:cpu_sup` is not available.
  Requires `m:cpu_sup`.

- percentage of OS disk space or partition used as returned by the `disksup:get_disk_data/0` `Capacity` field.
  The key map is a tuple of `:disk`/`disk` and disk/partition ID, with the key value being the percentage of space used.
  Requires `m:disksup`.

## Example

<!-- tabs-open -->
### Elixir

```elixir
iex(1)> :temporal_sdk_node.os_stats()
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
