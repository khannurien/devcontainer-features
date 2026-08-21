# opencode (opencode)

Installs the [opencode](https://opencode.ai) AI coding agent CLI into
`/usr/local/bin`, so it is available to every user inside the container.

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

- The binary lands in `/usr/local/bin`, independent of the container user.
- This Feature installs the tool; it does not provide opencode's config or
  credentials. Supply provider API keys via `remoteEnv`/`containerEnv`, or use
  [`opencode-host-config`](../opencode-host-config) to bind-mount your host
  config. To add the rtk proxy, add [`rtk`](../rtk) — or use
  [`opencode-rtk`](../opencode-rtk) for both.
