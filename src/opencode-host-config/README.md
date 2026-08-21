# opencode host config (opencode-host-config)

Bind-mounts your **host** opencode config into the container and links it into
the remote user's home:

| Host                        | Container mount        | Symlinked to                   |
| --------------------------- | ---------------------- | ------------------------------ |
| `~/.config/opencode`        | `/opencode-host/config` | `$HOME/.config/opencode`      |
| `~/.local/state/opencode`   | `/opencode-host/state`  | `$HOME/.local/state/opencode` |

That carries over your provider definitions and `opencode.json`, any plugin
packages opencode installed alongside it (`node_modules/`), your selected model,
prompt history and frecency data. Everything is read-write, so history written
in a container shows up on the host.

Pair it with [`opencode-rtk`](../opencode-rtk), which installs the actual
binaries. This is the opencode counterpart of
[`claude-host-config`](../claude-host-config).

## What is deliberately *not* shared

`~/.local/share/opencode` — the session store — is left out. Unlike Claude
Code's per-session JSONL transcripts, opencode keeps sessions in a single
SQLite database (`opencode.db`) in WAL mode, and pointing the host and several
containers at one such file read-write invites lock contention and corruption.
Its `snapshot/` and `repos/` subdirectories also hold host-absolute paths that
do not resolve inside a container.

Containers therefore start with an empty session history. If you accept the
risk, add the mount yourself in a fork or in a project's `devcontainer.json`:

```jsonc
"mounts": [
    "source=${localEnv:HOME}/.local/share/opencode,target=/home/vscode/.local/share/opencode,type=bind"
]
```

## Intended usage: personal, not committed

Because the mounts are Feature metadata, they cannot be switched off with an
option — anyone who adds this Feature gets them. So don't commit it to a shared
`devcontainer.json`. Put it in your **user** settings instead:

```jsonc
// VS Code user settings.json
"dev.containers.defaultFeatures": {
    "ghcr.io/khannurien/devcontainer-features/opencode-rtk:1": {},
    "ghcr.io/khannurien/devcontainer-features/opencode-host-config:1": {}
}
```

The `devcontainer` CLI equivalent is `--additional-features`.

## Requirements

- `~/.config/opencode` and `~/.local/state/opencode` must **exist on the host**;
  Docker creates a missing bind source as an empty root-owned directory. Run
  opencode once locally first.
- The container user needs a matching uid (1000 in every
  `mcr.microsoft.com/devcontainers` image) or the mounted files will not be
  writable.
- Your host config always wins over anything written at build time, in either
  install order: if `rtk init -g --opencode` runs first, this Feature replaces
  the directory it wrote with the symlink; if it runs second, it writes into
  `/opencode-host/config` in the image layer, which the bind mount then shadows
  at runtime.
- If your `opencode.json` points at a provider on `localhost` (a local
  llama.cpp or Ollama server, say), the container needs
  `"runArgs": ["--network=host"]` to reach it.
