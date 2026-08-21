# devcontainer-features

A collection of [dev container Features](https://containers.dev/implementors/features/).

## Features

| Feature                                    | Description                                                         |
| ------------------------------------------ | ------------------------------------------------------------------- |
| [`claude-code-rtk`](./src/claude-code-rtk) | Installs the Claude Code CLI and the rtk output proxy.              |
| [`opencode-rtk`](./src/opencode-rtk)       | Installs the opencode AI coding agent CLI and the rtk output proxy. |

## Usage

Add a Feature to any project's `.devcontainer/devcontainer.json`:

```jsonc
"features": {
    "ghcr.io/khannurien/devcontainer-features/opencode-rtk:1": {}
}
```

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
