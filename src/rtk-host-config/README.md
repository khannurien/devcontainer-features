# rtk host config (rtk-host-config)

Bind-mounts your **host** rtk config into the container and links it into the
remote user's home:

| Host              | Container mount    | Symlinked to          |
| ----------------- | ------------------ | --------------------- |
| `~/.config/rtk`   | `/rtk-host/config` | `$HOME/.config/rtk`   |

So rtk inside the container uses your own `config.toml` and custom
`filters.toml` rather than defaults. Read-write, so edits made in a container
reach the host.

The indirection through `/rtk-host` exists because a Feature cannot know the
remote user's home directory at mount time — the symlink is created at build
time, when `_REMOTE_USER_HOME` *is* known.

Pair it with [`rtk`](../rtk), which installs the binary.

## What is deliberately *not* shared

`~/.local/share/rtk` — where rtk keeps `history.db`, the SQLite database behind
`rtk gain`. Pointing the host and several containers at one SQLite file
read-write invites lock contention, and per-container savings stats are rarely
worth it. Each container therefore starts its own history.

## Intended usage: personal, not committed

Because the mount is Feature metadata, it cannot be switched off with an option
— anyone who adds this Feature gets it. So don't commit it to a shared
`devcontainer.json`; put it in your **user** settings instead:

```jsonc
// VS Code user settings.json
"dev.containers.defaultFeatures": {
    "ghcr.io/khannurien/devcontainer-features/rtk:1": {},
    "ghcr.io/khannurien/devcontainer-features/rtk-host-config:1": {}
}
```

## Requirements

- `~/.config/rtk` must **exist on the host**; Docker creates a missing bind
  source as an empty root-owned directory. Run rtk once locally first.
- The container user needs a matching uid (1000 in every
  `mcr.microsoft.com/devcontainers` image).
