#!/usr/bin/env bash
# Installs Claude Code + rtk into /usr/local/bin (available to every container user)
# and optionally wires rtk into Claude Code for the remote user.
set -euo pipefail

# Feature options arrive as uppercased env vars matching the option ids.
CLAUDE_VERSION="${CLAUDEVERSION:-stable}"
INSTALL_RTK="${INSTALLRTK:-true}"
RTK_INIT_CLAUDE="${RTKINITCLAUDE:-true}"

# Provided by the dev container build for the user the container runs as.
USERNAME="${_REMOTE_USER:-root}"
USER_HOME="${_REMOTE_USER_HOME:-/root}"

echo "[claude-code-rtk] remote user: ${USERNAME} (${USER_HOME})"

ensure_pkg() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "[claude-code-rtk] installing build dependency: $2"
		apt-get update -y
		apt-get install -y --no-install-recommends "$2"
	fi
}

ensure_pkg curl curl
ensure_pkg tar tar

# The official installers write into $HOME; run them under a throwaway HOME and
# then relocate the resulting binaries to a system-wide location on PATH.
TMP_HOME="$(mktemp -d)"
cleanup() { rm -rf "${TMP_HOME}"; }
trap cleanup EXIT

# --- Claude Code ----------------------------------------------------------
# The native installer needs no Node.js. It drops a launcher symlink at
# $HOME/.local/bin/claude pointing into $HOME/.local/share/claude/versions/,
# so resolve the symlink and install the real binary.
echo "[claude-code-rtk] installing Claude Code (${CLAUDE_VERSION})"
HOME="${TMP_HOME}" bash -c "curl -fsSL https://claude.ai/install.sh | bash -s -- '${CLAUDE_VERSION}'"
CLAUDE_LAUNCHER="${TMP_HOME}/.local/bin/claude"
if [ ! -e "${CLAUDE_LAUNCHER}" ]; then
	CLAUDE_LAUNCHER="$(find "${TMP_HOME}" -name claude -type f -perm -u+x 2>/dev/null | head -1)"
fi
CLAUDE_BIN="$(readlink -f "${CLAUDE_LAUNCHER}")"
if [ -z "${CLAUDE_BIN}" ] || [ ! -f "${CLAUDE_BIN}" ]; then
	echo "[claude-code-rtk] could not locate the installed claude binary" >&2
	exit 1
fi
install -m 0755 "${CLAUDE_BIN}" /usr/local/bin/claude
echo "[claude-code-rtk] claude -> $(HOME="${TMP_HOME}" /usr/local/bin/claude --version 2>/dev/null || echo '?')"

# --- rtk ------------------------------------------------------------------
if [ "${INSTALL_RTK}" = "true" ]; then
	echo "[claude-code-rtk] installing rtk"
	HOME="${TMP_HOME}" sh -c "curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"
	RTK_BIN="${TMP_HOME}/.local/bin/rtk"
	if [ ! -f "${RTK_BIN}" ]; then
		RTK_BIN="$(find "${TMP_HOME}" -name rtk -type f 2>/dev/null | head -1)"
	fi
	install -m 0755 "${RTK_BIN}" /usr/local/bin/rtk
	echo "[claude-code-rtk] rtk -> $(/usr/local/bin/rtk --version 2>/dev/null || echo '?')"

	# Registers the 'rtk hook claude' PreToolUse hook in ~/.claude/settings.json.
	# Note: a bind-mounted host ~/.claude shadows this at runtime, in which case
	# the host's own settings.json (and its hook) is what Claude Code reads.
	if [ "${RTK_INIT_CLAUDE}" = "true" ]; then
		echo "[claude-code-rtk] running 'rtk init -g' for ${USERNAME}"
		if [ "${USERNAME}" = "root" ]; then
			HOME="${USER_HOME}" /usr/local/bin/rtk init -g || echo "[claude-code-rtk] rtk init failed (non-fatal)"
		else
			su "${USERNAME}" -c "HOME='${USER_HOME}' /usr/local/bin/rtk init -g" || echo "[claude-code-rtk] rtk init failed (non-fatal)"
		fi
	fi
fi

echo "[claude-code-rtk] done."
