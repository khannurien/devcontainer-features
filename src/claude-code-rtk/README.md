# Claude Code + rtk (claude-code-rtk)

Convenience Feature. It installs nothing itself — it declares `dependsOn` on
[`claude-code`](../claude-code) and [`rtk`](../rtk) (with `init: claude-code`),
so adding this one line gets you both:

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/claude-code-rtk:1": {}
}
```

Equivalent to:

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/claude-code:1": {},
    "ghcr.io/khannurien/devcontainer-features/rtk:1": { "init": "claude-code" }
}
```

## No options

A Feature cannot forward its own option values into `dependsOn` — that block is
static metadata. So this Feature deliberately has no options: to pin a version,
use `claude-code` and `rtk` directly, as in the expansion above.

## See also

- [`claude-host-config`](../claude-host-config) — sign in with your host
  credentials, memory and history.
- [`rtk-host-config`](../rtk-host-config) — use your own rtk filters.
