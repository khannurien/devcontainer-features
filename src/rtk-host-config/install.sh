#!/usr/bin/env bash
# Links the bind-mounted host rtk config into the remote user's home. The mount
# itself is declared in devcontainer-feature.json; it lands under /rtk-host
# because a Feature cannot know the remote user's home at mount time. This
# script bridges that gap with a symlink.
set -euo pipefail

USERNAME="${_REMOTE_USER:-root}"
USER_HOME="${_REMOTE_USER_HOME:-/root}"

echo "[rtk-host-config] remote user: ${USERNAME} (${USER_HOME})"

# Mount point, so the bind target exists in the image rather than being
# conjured as a root-owned directory at container creation.
mkdir -p /rtk-host/config

LINK="${USER_HOME}/.config/rtk"
mkdir -p "$(dirname "${LINK}")"
# 'rtk init' may have created a real directory here; the host config wins.
rm -rf "${LINK}"
ln -s /rtk-host/config "${LINK}"
chown -h "${USERNAME}" "${LINK}" 2>/dev/null || true
chown "${USERNAME}" "${USER_HOME}/.config" 2>/dev/null || true
echo "[rtk-host-config] ${LINK} -> /rtk-host/config"

echo "[rtk-host-config] done."
