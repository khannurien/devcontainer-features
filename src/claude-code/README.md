# Claude Code (claude-code)

Installs the [Claude Code](https://claude.com/claude-code) CLI into
`/usr/local/bin`, so it is available to every user inside the container.

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

- The binary lands in `/usr/local/bin`, independent of the container user, and
  is a self-contained copy — `claude update` inside the container cannot replace
  it. Rebuild the container to pick up a new version.
- It is large (~325 MB), so expect the image to grow by roughly that much.
- To sign in with your host credentials and memory, add
  [`claude-host-config`](../claude-host-config). To add the rtk proxy, add
  [`rtk`](../rtk) — or use [`claude-code-rtk`](../claude-code-rtk) for both.
