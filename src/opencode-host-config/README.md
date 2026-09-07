# opencode host config (opencode-host-config)

Bind-mounts your **host** opencode config into the container and links it into
the remote user's home:

| Host                      | Container mount         | Symlinked to                  |
| ------------------------- | ----------------------- | ----------------------------- |
| `~/.config/opencode`      | `/opencode-host/config` | `$HOME/.config/opencode`      |
| `~/.local/state/opencode` | `/opencode-host/state`  | `$HOME/.local/state/opencode` |
| `~/.local/share/opencode` | `/opencode-host/data`   | `$HOME/.local/share/opencode` |

That carries over your provider definitions and `opencode.json`, any plugin
packages opencode installed alongside it (`node_modules/`), your selected model,
prompt history, frecency data and your session history (`opencode.db` and
`storage/`). Everything is read-write, so sessions started in a container show
up on the host and the other way round.

Pair it with [`opencode-rtk`](../opencode-rtk), which installs the actual
binaries. This is the opencode counterpart of
[`claude-host-config`](../claude-host-config).

## Session history is keyed by absolute path

Sharing `~/.local/share/opencode` makes sessions persist across rebuilds and
land on the host. It does not, on its own, show you the host's sessions for the
repo you are working in.

opencode scopes sessions to a project row keyed by the worktree's absolute
path. `session.project_id` references `project.worktree`, `session.directory`
is absolute, and the snapshot store is laid out as
`snapshot/<project.id>/<sha1(worktree)>/`. VS Code mounts your workspace at
`/workspaces/<folder-name>` by default, so a container registers a second
project for that path and starts with an empty session list.

To get one shared history per repo, mount the workspace at its host path in the
project's `devcontainer.json`:

```jsonc
"workspaceMount": "source=${localWorkspaceFolder},target=${localWorkspaceFolder},type=bind",
"workspaceFolder": "${localWorkspaceFolder}"
```

A Feature cannot set those two keys, so they have to live in the
`devcontainer.json`.

Note. Claude Code behaves the same way, keying transcripts by cwd under
`~/.claude/projects/`, so the same `workspaceMount` recipe applies to
[`claude-host-config`](../claude-host-config).

## Concurrent access

Running opencode on the host and in containers at the same time points several
processes at one SQLite database (`opencode.db`, WAL mode). On Linux a bind
mount is the same inode on the same filesystem seen from another mount
namespace, and fcntl locks are held by the kernel against the inode, so this is
equivalent to running several opencode processes on the host.

On Docker Desktop for macOS and Windows the bind goes through virtiofs, where
SQLite locking across the VM boundary is not reliable. Don't share the session
store read-write from more than one place there.

## Intended usage: personal, not committed

Because the mounts are Feature metadata, they cannot be switched off with an
option — anyone who adds this Feature gets them. So don't commit it to a shared
`devcontainer.json`. Put it in your **user** settings instead:

```jsonc
// VS Code user settings.json
"dev.containers.defaultFeatures": {
    "ghcr.io/khannurien/devcontainer-features/opencode-rtk:2": {},
    "ghcr.io/khannurien/devcontainer-features/opencode-host-config:1": {}
}
```

The `devcontainer` CLI equivalent is `--additional-features`.

## Requirements

- `~/.config/opencode`, `~/.local/state/opencode` and `~/.local/share/opencode`
  must **exist on the host**; Docker creates a missing bind source as an empty
  root-owned directory. Run opencode once locally first.
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
