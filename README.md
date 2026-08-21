# devcontainer-features

A collection of [dev container Features](https://containers.dev/implementors/features/).

## Features

| Feature                                              | Description                                                           |
| ---------------------------------------------------- | --------------------------------------------------------------------- |
| [`claude-code-rtk`](./src/claude-code-rtk)           | Installs the Claude Code CLI and the rtk output proxy.                |
| [`claude-host-config`](./src/claude-host-config)     | Bind-mounts the host's Claude Code and rtk config into the container. |
| [`opencode-rtk`](./src/opencode-rtk)                 | Installs the opencode AI coding agent CLI and the rtk output proxy.   |
| [`opencode-host-config`](./src/opencode-host-config) | Bind-mounts the host's opencode config into the container.            |

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
    "ghcr.io/khannurien/devcontainer-features/claude-host-config:1": {}
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
devcontainer features test -f claude-code-rtk -i mcr.microsoft.com/devcontainers/base:noble .
devcontainer features test -f opencode-rtk -i mcr.microsoft.com/devcontainers/base:noble .
```
