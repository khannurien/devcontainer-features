# opencode + rtk (opencode-rtk)

Convenience Feature. It installs nothing itself — it declares `dependsOn` on
[`opencode`](../opencode) and [`rtk`](../rtk) (with `init: opencode`), so adding
this one line gets you both:

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/opencode-rtk:2": {}
}
```

Equivalent to:

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/opencode:1": {},
    "ghcr.io/khannurien/devcontainer-features/rtk:1": { "init": "opencode" }
}
```

## No options — breaking change in 2.0.0

Version 1.x was self-contained and took `opencodeVersion`, `installRtk` and
`rtkInitOpencode` options. A Feature cannot forward its own option values into
`dependsOn` (that block is static metadata), so 2.0.0 drops them: to pin a
version, use `opencode` and `rtk` directly, as in the expansion above.

`ghcr.io/khannurien/devcontainer-features/opencode-rtk:1` still resolves to the
old self-contained 1.0.0 and is unaffected — but note that its `rtkInitOpencode`
step never actually worked: it called `rtk init -g --opencode` without creating
`~/.claude` first and without `--auto-patch`, so rtk exited 1 and the failure was
swallowed as non-fatal. 2.0.0 fixes that by way of the `rtk` Feature.

## See also

- [`opencode-host-config`](../opencode-host-config) — your providers, plugins,
  selected model and prompt history.
- [`rtk-host-config`](../rtk-host-config) — use your own rtk filters.
