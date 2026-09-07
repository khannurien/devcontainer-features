# Claude Code + rtk (claude-code-rtk)

Convenience Feature. It installs nothing itself — it declares `dependsOn` on
[`claude-code`](../claude-code) and [`rtk`](../rtk) (with `init: claude-code`),
so adding this one line gets you both:

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/claude-code-rtk:2": {}
}
```

Equivalent to:

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/claude-code:1": {},
    "ghcr.io/khannurien/devcontainer-features/rtk:1": { "init": "claude-code" }
}
```

## No options — breaking change in 2.0.0

Version 1.x was self-contained and took `claudeVersion`, `installRtk` and
`rtkInitClaude` options. A Feature cannot forward its own option values into
`dependsOn` (that block is static metadata), so 2.0.0 drops them: to pin a
version, use `claude-code` and `rtk` directly, as in the expansion above.

Use the `:2` tag. `ghcr.io/khannurien/devcontainer-features/claude-code-rtk:1`
still resolves to the old self-contained 1.0.0, which copies a snapshot of the
`claude` binary into `/usr/local/bin`. That copy cannot be updated in place:
`claude update` installs a second Claude Code under `$HOME/.local`, and which
one runs depends on PATH order. Rebuilding without cache does not help, because
the stale copy is what version 1.0.0 installs. 2.0.0 fixes that by way of the
`claude-code` Feature.

## See also

- [`claude-host-config`](../claude-host-config) — sign in with your host
  credentials, memory and history.
- [`rtk-host-config`](../rtk-host-config) — use your own rtk filters.
