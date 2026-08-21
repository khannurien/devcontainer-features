#!/usr/bin/env bash
# Links the bind-mounted host Claude Code / rtk config into the remote user's
# home. The mounts themselves are declared in devcontainer-feature.json; they
# land under /claude-host because a Feature cannot know the remote user's home
# at mount time. This script bridges that gap with symlinks.
set -euo pipefail

USERNAME="${_REMOTE_USER:-root}"
USER_HOME="${_REMOTE_USER_HOME:-/root}"

echo "[claude-host-config] remote user: ${USERNAME} (${USER_HOME})"

# Mount points, so the bind targets exist in the image rather than being
# conjured as root-owned directories at container creation.
mkdir -p /claude-host/claude /claude-host/rtk
[ -e /claude-host/claude.json ] || : > /claude-host/claude.json

link() {
	local target="$1" link="$2"
	mkdir -p "$(dirname "${link}")"
	# The tools' own installers may have created a real file or directory here
	# (e.g. 'rtk init -g' writing ~/.claude/settings.json). The host config wins.
	rm -rf "${link}"
	ln -s "${target}" "${link}"
	chown -h "${USERNAME}" "${link}" 2>/dev/null || true
	echo "[claude-host-config] ${link} -> ${target}"
}

link /claude-host/claude "${USER_HOME}/.claude"
link /claude-host/claude.json "${USER_HOME}/.claude.json"
link /claude-host/rtk "${USER_HOME}/.config/rtk"

# ~/.config may have been created by the mkdir above while running as root.
chown "${USERNAME}" "${USER_HOME}/.config" 2>/dev/null || true

echo "[claude-host-config] done."
