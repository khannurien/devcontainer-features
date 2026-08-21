# Claude Code + rtk (claude-code-rtk)

Installs the [Claude Code](https://claude.com/claude-code) CLI and the
[rtk](https://github.com/rtk-ai/rtk) token-optimizing output proxy into
`/usr/local/bin`, so both are available to every user inside the container.
Optionally runs `rtk init -g` for the remote user to wire rtk into Claude Code.

Claude Code is installed with the official native installer, so the container
does **not** need Node.js.

## Example usage

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/claude-code-rtk:1": {}
}
```

## Options

| Option          | Type    | Default  | Description                                                                  |
| --------------- | ------- | -------- | ---------------------------------------------------------------------------- |
| `claudeVersion` | string  | `stable` | Claude Code version to install (`stable`, `latest`, or a pinned version).     |
| `installRtk`    | boolean | `true`   | Install the rtk CLI proxy.                                                    |
| `rtkInitClaude` | boolean | `true`   | Run `rtk init -g` for the remote user.                                        |

## Pin a version

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/claude-code-rtk:1": {
        "claudeVersion": "2.1.238"
    }
}
```

## Sharing your host Claude config

This Feature installs the tools; it does not provide Claude Code's config or
credentials. A Feature cannot declare these mounts itself — Feature-contributed
`mounts` only support `${devcontainerId}` substitution, not `${localEnv:HOME}` —
so add them to the consuming `devcontainer.json`:

```jsonc
"mounts": [
    // Auth, global CLAUDE.md, settings.json (hooks), plugins, session history
    "source=${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached",
    // Onboarding flags, account and user-scoped MCP servers
    "source=${localEnv:HOME}/.claude.json,target=/home/vscode/.claude.json,type=bind,consistency=cached",
    // rtk's config and custom filters
    "source=${localEnv:HOME}/.config/rtk,target=/home/vscode/.config/rtk,type=bind,consistency=cached"
]
```

Adjust the target to the container user's home: `/home/vscode` for most
`mcr.microsoft.com/devcontainers` images, `/home/node` for the Node/TypeScript
ones, `/root` when `remoteUser` is root.

Sharing `~/.claude.json` is what skips the first-run onboarding prompts in every
container. Mounting `~/.claude` read-write also means anything in the container
can read `~/.claude/.credentials.json` and rewrite your host settings — mount it
read-only (`,readonly`) if that matters more to you than a writable history.

## Notes

- Binaries land in `/usr/local/bin`, independent of the container user, and are
  a self-contained copy — `claude update` inside the container will not be able
  to replace them. Rebuild the container to pick up a new version instead.
- The Claude Code binary is large (~325 MB), so expect the image to grow by
  roughly that much.
- `rtk init -g` writes `~/.claude/settings.json` at build time. If you bind-mount
  a host `~/.claude` over that path, the host file wins at runtime — which is
  usually what you want, since it already carries your own hook configuration.
