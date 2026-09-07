#!/bin/bash
set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "opencode on PATH" bash -c "command -v opencode"
check "opencode runs" opencode --version

# The point of installing into $HOME is that there is exactly one opencode, in
# the layout 'opencode upgrade' writes to, so an upgrade cannot leave a stale
# second copy behind — nor stop on the "may be managed by a package manager"
# prompt, which hangs a non-interactive shell.
check "exactly one opencode install" bash -c '[ "$(type -aP opencode | xargs -r -n1 readlink -f | sort -u | wc -l)" -eq 1 ]'
check "install lives in the user's home" bash -c '[ "$(readlink -f "$(command -v opencode)")" = "$HOME/.opencode/bin/opencode" ]'
check "install is writable by the user" bash -c '[ -w "$HOME/.opencode/bin/opencode" ]'

# /usr/local/bin/opencode covers shells that read neither profile nor rc files.
# It must be a symlink, never a copy, or it can go stale on the next upgrade.
check "system-wide entry is a symlink, not a copy" bash -c '[ -L /usr/local/bin/opencode ]'
check "opencode found without profile or rc" env -i HOME="$HOME" PATH=/usr/local/bin:/usr/bin:/bin sh -c 'opencode --version'

# 'opencode upgrade' must reach the version check rather than the ownership
# prompt. Running it against the version already installed is a no-op that still
# exercises that detection, and must not block on stdin.
check "upgrade does not prompt about a package-managed copy" bash -c \
	'timeout 120 opencode upgrade "$(opencode --version)" </dev/null 2>&1 | tee /tmp/oc-upgrade.log; ! grep -qi "managed by a package manager\|Install anyways" /tmp/oc-upgrade.log'

reportResults
