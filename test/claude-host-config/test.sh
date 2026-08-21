#!/bin/bash
set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "~/.claude is a symlink" bash -c "[ -L \"\$HOME/.claude\" ]"
check "~/.claude points at the mount" bash -c "[ \"\$(readlink \"\$HOME/.claude\")\" = /claude-host/claude ]"
check "~/.claude.json is a symlink" bash -c "[ -L \"\$HOME/.claude.json\" ]"
check "~/.config/rtk is a symlink" bash -c "[ -L \"\$HOME/.config/rtk\" ]"
check "mounts are present" bash -c "mount | grep -q /claude-host/claude"

reportResults
