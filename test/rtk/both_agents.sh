#!/bin/bash
set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "rtk runs" rtk --version

# 'rtk init --opencode' claims to cover Claude Code as well, but as of rtk
# 0.48.0 it only installs the opencode plugin. With both agents present, each
# has to be wired by its own invocation.
check "Claude Code hook installed" bash -c 'grep -q "rtk hook claude" "$HOME/.claude/settings.json"'
check "RTK.md written for Claude Code" bash -c '[ -f "$HOME/.claude/RTK.md" ]'
check "opencode plugin installed" bash -c '[ -f "$HOME/.config/opencode/plugins/rtk.ts" ]'

reportResults
