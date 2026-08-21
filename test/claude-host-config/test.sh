#!/bin/bash
set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "~/.claude is a symlink" bash -c "[ -L \"\$HOME/.claude\" ]"
check "~/.claude points at the mount" bash -c "[ \"\$(readlink \"\$HOME/.claude\")\" = /claude-host/claude ]"
check "~/.claude.json is a symlink" bash -c "[ -L \"\$HOME/.claude.json\" ]"
check "~/.claude.json points inside the mount" bash -c "[ \"\$(readlink \"\$HOME/.claude.json\")\" = /claude-host/claude/.claude.json ]"
check "CLAUDE_CONFIG_DIR is set" bash -c "[ \"\$CLAUDE_CONFIG_DIR\" = /claude-host/claude ]"
check "mounts are present" bash -c "mount | grep -q /claude-host/claude"
check "seed hook is installed" bash -c "[ -x /usr/local/share/claude-host-config/seed.sh ]"
check "state file was seeded" bash -c "[ -s \"\$HOME/.claude.json\" ]"

# The whole point of the change: the state file must live inside the *directory*
# mount, so Claude Code's write-temp-then-rename lands on the host instead of on
# an inode that a file bind mount has pinned and the host has already unlinked.
check "state file survives an atomic rewrite" bash -c '
	set -e
	tmp="$CLAUDE_CONFIG_DIR/.claude.json.test.$$"
	cp "$CLAUDE_CONFIG_DIR/.claude.json" "$tmp"
	mv "$tmp" "$CLAUDE_CONFIG_DIR/.claude.json"
	[ "$(stat -c %h "$CLAUDE_CONFIG_DIR/.claude.json")" -ge 1 ]
'

reportResults
