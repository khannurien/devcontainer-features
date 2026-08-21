# devcontainer-features

A collection of [dev container Features](https://containers.dev/implementors/features/).

## Features

| Feature                                              | Description                                                                        |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------- |
| [`claude-code`](./src/claude-code)                   | Installs the Claude Code CLI (native installer, no Node needed).                   |
| [`opencode`](./src/opencode)                         | Installs the opencode AI coding agent CLI.                                         |
| [`rtk`](./src/rtk)                                   | Installs the rtk token-optimizing CLI proxy, and wires it into the agents present. |
| [`claude-host-config`](./src/claude-host-config)     | Bind-mounts the host's Claude Code config into the container.                      |
| [`opencode-host-config`](./src/opencode-host-config) | Bind-mounts the host's opencode config into the container.                         |
| [`rtk-host-config`](./src/rtk-host-config)           | Bind-mounts the host's rtk config and filters into the container.                  |
| [`claude-code-rtk`](./src/claude-code-rtk)           | Convenience: `claude-code` + `rtk` in one line.                                    |
| [`opencode-rtk`](./src/opencode-rtk)                 | Convenience: `opencode` + `rtk` in one line.                                       |

The Features come in three pairs: one that installs a tool, one that shares your
host config for it. The two `*-rtk` Features are thin `dependsOn` wrappers for
the common combinations.

## Usage

Add a Feature to any project's `.devcontainer/devcontainer.json`:

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/opencode-rtk:1": {}
}
```

To get a Feature in *every* dev container you open without touching any repo,
put it in your VS Code **user** settings instead — the project's own
`devcontainer.json` stays clean and buildable by everyone else:

```jsonc
"dev.containers.defaultFeatures": {
    "ghcr.io/khannurien/devcontainer-features/claude-code-rtk:1": {},
    "ghcr.io/khannurien/devcontainer-features/claude-host-config:1": {},
    "ghcr.io/khannurien/devcontainer-features/rtk-host-config:1": {}
}
```

The `devcontainer` CLI equivalent is `--additional-features '{...}'`.

## Publishing

Features are published to GHCR by `.github/workflows/release.yaml` on push to
`main`. Ensure GitHub Packages is enabled for the repo; the workflow uses the
built-in `GITHUB_TOKEN`. After the first publish, set the package visibility to
public if you want to consume it from other repos without authentication.

## Testing locally

```sh
npm install -g @devcontainers/cli
devcontainer features test -f claude-code -i mcr.microsoft.com/devcontainers/base:noble .
```

The two `*-rtk` Features resolve their `dependsOn` from GHCR, so they can only
be tested once the Features they depend on have been published at least once.
