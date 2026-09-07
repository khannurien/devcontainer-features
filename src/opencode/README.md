# opencode (opencode)

Installs the [opencode](https://opencode.ai) AI coding agent CLI for the remote
user, using the same layout opencode's own upgrader uses.

## Example usage

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/opencode:1": {}
}
```

## Options

| Option            | Type   | Default  | Description                                              |
| ----------------- | ------ | -------- | -------------------------------------------------------- |
| `opencodeVersion` | string | `latest` | Version to install (`latest` or a pinned version).       |

## Notes

- The binary lands in `$HOME/.opencode/bin/opencode`. `opencode upgrade` works
  inside the container and replaces it in place.
- `$HOME/.opencode/bin` is added to `PATH` through `/etc/profile.d/opencode.sh`
  (the installer also adds its own line to the user's rc files).
  `/usr/local/bin/opencode` is a symlink to the binary, so shells that read
  neither (a `sh -c` lifecycle command under `"userEnvProbe": "none"`, say)
  still find it. Both names resolve to the same install.
- opencode is not relocatable: its installer hardcodes
  `INSTALL_DIR=$HOME/.opencode/bin`. Before v1.1.0 this Feature put a *copy* of
  the binary in `/usr/local/bin`, and `opencode upgrade` refused to touch it —
  it warned that opencode "is installed to `/usr/local/bin/opencode` and may be
  managed by a package manager" and stopped on an `Install anyways?` prompt,
  which hangs a non-interactive shell. Answering yes installed a second opencode
  under `$HOME`, leaving `PATH` order to decide which version ran. Hence the
  symlink.
- Because the install belongs to the remote user, other users in the container
  read it through that user's home rather than getting their own.
- This Feature installs the tool; it does not provide opencode's config or
  credentials. Supply provider API keys via `remoteEnv`/`containerEnv`, or use
  [`opencode-host-config`](../opencode-host-config) to bind-mount your host
  config. To add the rtk proxy, add [`rtk`](../rtk) — or use
  [`opencode-rtk`](../opencode-rtk) for both.
