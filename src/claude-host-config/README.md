# Claude Code host config (claude-host-config)

Bind-mounts your **host** Claude Code config into the container and
links it into the remote user's home:

| Host                | Container mount          | Symlinked to             |
| ------------------- | ------------------------ | ------------------------ |
| `~/.claude`         | `/claude-host/claude`    | `$HOME/.claude`          |
| `~/.claude.json`    | `/claude-host/claude.json` | `$HOME/.claude.json`   |

The result: Claude Code inside the container is already signed in, with your
global `CLAUDE.md`, your `settings.json` hooks, your plugins and your session
history. Everything is read-write, so history written in a container shows up
on the host.

The indirection through `/claude-host` exists because a Feature cannot know the
remote user's home directory at mount time — the symlinks are created at build
time, when `_REMOTE_USER_HOME` *is* known.

Pair it with [`claude-code`](../claude-code), which installs the binary. For
rtk's own settings and filters, add [`rtk-host-config`](../rtk-host-config).

## Intended usage: personal, not committed

Because the mounts are Feature metadata, they cannot be switched off with an
option — anyone who adds this Feature gets them. So don't commit it to a shared
`devcontainer.json`. Put it in your **user** settings instead, and every dev
container you open picks it up while the repo's own config stays clean and
buildable by everyone else:

```jsonc
// VS Code user settings.json
"dev.containers.defaultFeatures": {
    "ghcr.io/khannurien/devcontainer-features/claude-code-rtk:1": {},
    "ghcr.io/khannurien/devcontainer-features/claude-host-config:1": {},
    "ghcr.io/khannurien/devcontainer-features/rtk-host-config:1": {}
}
```

The `devcontainer` CLI equivalent is `--additional-features`:

```sh
devcontainer up --workspace-folder . \
  --additional-features '{"ghcr.io/khannurien/devcontainer-features/claude-host-config:1":{}}'
```

## Requirements

- `~/.claude` and `~/.claude.json` must **exist on the host**.
  Docker creates a missing bind source as an empty *directory*, which would give
  you a `~/.claude.json` that is a directory — on the host as well as in the
  container. Run Claude Code once locally first.
- The container user needs a matching uid (1000 in every
  `mcr.microsoft.com/devcontainers` image, which is also the usual Linux/WSL
  desktop uid) or the mounted files will not be writable.

## Security

Everything in the container can read `~/.claude/.credentials.json` — your OAuth
token — and can rewrite your host `settings.json`, `CLAUDE.md` and history.
That is the point of the Feature, but it means it belongs only in containers you
trust. Add `,readonly` to the mounts in a fork if you want the memory and
credentials without the write-back.
