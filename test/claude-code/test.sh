#!/bin/bash
set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "claude on PATH" bash -c "command -v claude"
check "claude runs" claude --version

# The point of installing into $HOME is that there is exactly one claude, in the
# layout 'claude update' writes to, so an update cannot leave a stale second
# copy behind. Every name on PATH must resolve to that one install.
check "exactly one claude install" bash -c '[ "$(type -aP claude | xargs -r -n1 readlink -f | sort -u | wc -l)" -eq 1 ]'
check "install lives in the user's version tree" bash -c 'readlink -f "$(command -v claude)" | grep -q "^$HOME/.local/share/claude/versions/"'
check "launcher is the user's" bash -c '[ -L "$HOME/.local/bin/claude" ]'
check "install is writable by the user" bash -c '[ -w "$HOME/.local/bin/claude" ] && [ -w "$HOME/.local/share/claude/versions" ]'

# /usr/local/bin/claude covers shells that read neither profile nor rc files. It
# must be a symlink, never a copy, or it can go stale on the next update.
check "system-wide entry is a symlink, not a copy" bash -c '[ -L /usr/local/bin/claude ]'
check "claude found without profile or rc" env -i HOME="$HOME" PATH=/usr/local/bin:/usr/bin:/bin sh -c 'claude --version'

reportResults
