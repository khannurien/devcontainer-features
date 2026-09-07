# Claude Code (claude-code)

Installs the [Claude Code](https://claude.com/claude-code) CLI for the remote
user, using the same layout Claude Code's own updater uses.

Uses the official **native** installer, so the container does not need Node.js —
unlike an `npm install -g @anthropic-ai/claude-code`, which is what the upstream
`ghcr.io/anthropics/devcontainer-features/claude-code` Feature does.

## Example usage

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/claude-code:1": {}
}
```

## Options

| Option          | Type   | Default  | Description                                                              |
| --------------- | ------ | -------- | ------------------------------------------------------------------------ |
| `claudeVersion` | string | `stable` | Version to install (`stable`, `latest`, or a pinned version).             |

## Notes

- The install goes to `$HOME/.local/share/claude/versions/`, with a launcher
  symlink at `$HOME/.local/bin/claude`. `claude update` and `claude install`
  work inside the container and replace it in place.
- `$HOME/.local/bin` is added to `PATH` through `/etc/profile.d/claude-code.sh`,
  which `.bashrc` and `.zshrc` also source. `/usr/local/bin/claude` is a symlink
  to the launcher, so shells that read neither (a `sh -c` lifecycle command
  under `"userEnvProbe": "none"`, say) still find it. Both names resolve to the
  same install, whatever version it is currently on.
- Claude Code is not relocatable: `claude install` and the auto-updater write to
  those fixed `$HOME` paths, and there is no option or environment variable to
  redirect them. Before v1.1.0 this Feature put a *copy* of the binary in
  `/usr/local/bin`; the first update inside the container then installed a
  second claude under `$HOME`, and `PATH` order decided which of the two
  versions ran. Hence the symlink.
- Because the install belongs to the remote user, other users in the container
  read it through that user's home rather than getting their own.
- It is large (~325 MB), so expect the image to grow by roughly that much.
- To sign in with your host credentials and memory, add
  [`claude-host-config`](../claude-host-config). To add the rtk proxy, add
  [`rtk`](../rtk) — or use [`claude-code-rtk`](../claude-code-rtk) for both.
