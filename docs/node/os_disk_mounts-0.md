Returns a list of mounted OS disks and partitions.

During SDK startup, `disksup:get_disk_data/0` is invoked once, and the list of disks or partitions
`Id` is cached in `m:persistent_term`.
This function returns a cached value, meaning it does not update when disks or partitions are
mounted or unmounted at runtime.
Function is internally used when initializing and validating OS rate limiter `disk` settings for new
workers.

Requires `m:disksup`.

## Example

<!-- tabs-open -->
### Elixir

```elixir
iex(1)> TemporalSdk.Node.os_disk_mounts()
[~c"/dev", ~c"/run", ~c"/", ~c"/dev/shm", ~c"/run/lock", ~c"/tmp",
 ~c"/boot/efi", ~c"/run/user/1001"]
```

### Erlang

```erlang
1> temporal_sdk_node:os_disk_mounts().
["/dev","/run","/","/dev/shm","/run/lock","/tmp",
 "/boot/efi","/run/user/1001"]
```
<!-- tabs-close -->
