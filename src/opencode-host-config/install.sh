#!/usr/bin/env bash
# Links the bind-mounted host opencode config into the remote user's home. The
# mounts themselves are declared in devcontainer-feature.json; they land under
# /opencode-host because a Feature cannot know the remote user's home at mount
# time. This script bridges that gap with symlinks.
set -euo pipefail

USERNAME="${_REMOTE_USER:-root}"
USER_HOME="${_REMOTE_USER_HOME:-/root}"

echo "[opencode-host-config] remote user: ${USERNAME} (${USER_HOME})"

# Mount points, so the bind targets exist in the image rather than being
# conjured as root-owned directories at container creation.
mkdir -p /opencode-host/config /opencode-host/state /opencode-host/data

link() {
	local target="$1" link="$2"
	mkdir -p "$(dirname "${link}")"
	# The tools' own installers may have created a real file or directory here
	# (e.g. 'rtk init -g --opencode' writing opencode.json). The host config wins.
	rm -rf "${link}"
	ln -s "${target}" "${link}"
	chown -h "${USERNAME}" "${link}" 2>/dev/null || true
	echo "[opencode-host-config] ${link} -> ${target}"
}

link /opencode-host/config "${USER_HOME}/.config/opencode"
link /opencode-host/state "${USER_HOME}/.local/state/opencode"
link /opencode-host/data "${USER_HOME}/.local/share/opencode"

# These may have been created by the mkdir above while running as root.
chown "${USERNAME}" "${USER_HOME}/.config" "${USER_HOME}/.local" \
	"${USER_HOME}/.local/state" "${USER_HOME}/.local/share" 2>/dev/null || true

echo "[opencode-host-config] done."
