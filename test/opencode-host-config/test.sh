#!/bin/bash
set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "~/.config/opencode is a symlink" bash -c "[ -L \"\$HOME/.config/opencode\" ]"
check "~/.config/opencode points at the mount" bash -c "[ \"\$(readlink \"\$HOME/.config/opencode\")\" = /opencode-host/config ]"
check "~/.local/state/opencode is a symlink" bash -c "[ -L \"\$HOME/.local/state/opencode\" ]"
check "mounts are present" bash -c "mount | grep -q /opencode-host/config"

reportResults
