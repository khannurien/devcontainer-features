# Claude Code host config (claude-host-config)

Bind-mounts your **host** Claude Code config into the container and points
Claude Code at it:

| Host                       | Container                        | How                             |
| -------------------------- | -------------------------------- | ------------------------------- |
| `~/.claude`                | `/claude-host/claude`            | bind mount + `$HOME/.claude` symlink |
| `~/.claude/.claude.json`   | `/claude-host/claude/.claude.json` | `CLAUDE_CONFIG_DIR` + `$HOME/.claude.json` symlink |
| `~/.claude.json`           | `/claude-host/claude.json`       | seed only, read once on first start |

The result: Claude Code inside the container is already signed in, with your
global `CLAUDE.md`, your `settings.json` hooks, your plugins, your per-project
trust and tool permissions, and your session history. Everything is read-write,
so a conversation started in a container is still there after a rebuild — and
shows up on the host too.

The indirection through `/claude-host` exists because a Feature cannot know the
remote user's home directory at mount time — the symlinks are created at build
time, when `_REMOTE_USER_HOME` *is* known.

Pair it with [`claude-code`](../claude-code), which installs the binary. For
rtk's own settings and filters, add [`rtk-host-config`](../rtk-host-config).

## Why `CLAUDE_CONFIG_DIR` instead of mounting `~/.claude.json`

Claude Code rewrites its state file atomically: it writes a temporary file next
to the target and `rename()`s it over the top. That replaces the **inode**.

A Docker bind mount of a *directory* follows renames inside it, but a bind mount
of a single *file* pins the inode it was created with. So `~/.claude.json`
mounted as a file works exactly once. The first time the host rewrites it, the
container is left holding an unlinked inode:

```console
$ docker exec -u vscode <container> stat -c '%n ino=%i links=%h' /claude-host/claude.json
/claude-host/claude.json ino=1233003 links=0        # links=0 — the file is gone
$ stat -c '%n ino=%i links=%h' ~/.claude.json
/home/vincent/.claude.json ino=2681908 links=1      # different inode entirely
```

Every write the container makes from then on goes to that dead inode: silently
accepted, never visible to the host, discarded when the container is removed.
That is per-project state — `lastSessionId`, `hasTrustDialogAccepted`,
`allowedTools`, MCP approvals — so each rebuild came back with the trust dialog,
the permission prompts and `claude --continue` finding nothing to continue.

Setting `CLAUDE_CONFIG_DIR=/claude-host/claude` moves that state file *inside*
the directory mount, where the rename is an ordinary rename on the host
filesystem and everything lands for real. `$HOME/.claude.json` stays as a
symlink into the same place: a symlink is resolved at every `open()`, so unlike a
bind mount it keeps tracking the file across renames.

One consequence: the container's state file is the host's
`~/.claude/.claude.json`, **not** the host's `~/.claude.json`. Those stay
separate unless you also set `CLAUDE_CONFIG_DIR` on the host — see below. On
first start the Feature seeds the container-side file from your host
`~/.claude.json` so you are not dropped at the onboarding screen.

### Optional: one config file for host and containers

If you want the host and every container to share a single state file, point the
host at the same directory and move the file into it:

```sh
mv ~/.claude.json ~/.claude/.claude.json
echo 'export CLAUDE_CONFIG_DIR="$HOME/.claude"' >> ~/.bashrc
: > ~/.claude.json   # keep an empty file: it is still a bind source
```

The last line matters — Docker creates a missing bind source as an empty
*directory*, and you do not want `~/.claude.json` to become one.

## Sessions are keyed by absolute path

Claude Code files transcripts under `~/.claude/projects/<cwd-with-slashes-
replaced>/`. The same repo is `/home/you/git/foo` on the host and
`/workspaces/foo` in the container, so those are two different projects. A
conversation you started on the host will not appear in `claude --resume` inside
the container, and vice versa. This Feature makes container sessions *persist*;
it cannot make the two path namespaces the same.

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
