# opencode + rtk (opencode-rtk)

Installs the [opencode](https://opencode.ai) AI coding agent CLI and the
[rtk](https://github.com/rtk-ai/rtk) token-optimizing output proxy into
`/usr/local/bin`, so both are available to every user inside the container.
Optionally runs `rtk init -g --opencode` for the remote user to wire rtk into
opencode.

## Example usage

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/opencode-rtk:1": {}
}
```

## Options

| Option            | Type    | Default  | Description                                                          |
| ----------------- | ------- | -------- | ------------------------------------------------------------------- |
| `opencodeVersion` | string  | `latest` | opencode version to install (`latest` or a pinned version).         |
| `installRtk`      | boolean | `true`   | Install the rtk CLI proxy.                                          |
| `rtkInitOpencode` | boolean | `true`   | Run `rtk init -g --opencode` for the remote user.                  |

## Pin a version

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/opencode-rtk:1": {
        "opencodeVersion": "1.17.9"
    }
}
```

## Notes

- Binaries land in `/usr/local/bin`, independent of the container user.
- This Feature installs the tools; it does not provide opencode's config or
  credentials. Mount those separately (e.g. bind-mount `~/.config/opencode`)
  and supply provider API keys via `remoteEnv`/`containerEnv`.
