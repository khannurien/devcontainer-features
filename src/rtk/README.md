# rtk (rtk)

Installs the [rtk](https://github.com/rtk-ai/rtk) (Rust Token Killer)
token-optimizing CLI proxy into `/usr/local/bin`, so it is available to every
user inside the container — including the hook subshells the agents spawn.

## Example usage

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/rtk:1": {}
}
```

## Options

| Option       | Type   | Default  | Description                                                                                  |
| ------------ | ------ | -------- | -------------------------------------------------------------------------------------------- |
| `rtkVersion` | string | `latest` | Version to install (`latest` or a release tag such as `v0.45.0`).                             |
| `init`       | string | `auto`   | Agents to wire rtk into: `auto`, `none`, `claude-code`, `opencode`, `both`.                   |

`init: auto` wires up whichever agents it finds. Because this Feature declares
`installsAfter` on [`claude-code`](../claude-code) and
[`opencode`](../opencode), the detection sees whatever those Features installed;
it looks in the remote user's home as well as on `PATH`, since both agents
install themselves there.

`rtk init --help` describes `--opencode` as "in addition to Claude Code", but as
of rtk 0.48.0 that run only installs the opencode plugin — it leaves
`settings.json` untouched and writes no `RTK.md`. So `init: both` runs `rtk init`
once per agent, and `init: opencode` wires opencode alone.

## Notes

- `rtk init` writes the agent's config in the remote user's home at build time:
  `RTK.md`, an `@RTK.md` import in `CLAUDE.md`, and the `rtk hook claude`
  PreToolUse hook in `settings.json`. If you also bind-mount a host config
  ([`claude-host-config`](../claude-host-config),
  [`opencode-host-config`](../opencode-host-config)), the host file shadows it at
  runtime — which is usually what you want, since it already carries your own
  hook configuration. Set `init: none` to skip the build-time write entirely.
- Three details make `rtk init` work unattended, and this Feature handles all
  three: rtk does not create the agent's config directory and exits 1 if it is
  missing; without `--auto-patch` it prompts before touching `settings.json` and
  so installs no hook in a build; and a detected custom filter would otherwise
  prompt too. Filter trust that matters is the host's, and travels with
  [`rtk-host-config`](../rtk-host-config) at runtime.
- rtk has no self-update command, so a copy in `/usr/local/bin` cannot go stale
  behind your back and stays a plain system-wide install. The
  [`claude-code`](../claude-code) and [`opencode`](../opencode) Features install
  into the remote user's home instead, because those two tools *do* update
  themselves and write to fixed `$HOME` paths. Rebuild the container to move rtk
  to a new version.
- To use your own rtk settings and custom filters, add
  [`rtk-host-config`](../rtk-host-config).
