#!/usr/bin/env bash
# Installs the Claude Code CLI into /usr/local/bin (available to every container user).
set -euo pipefail

CLAUDE_VERSION="${CLAUDEVERSION:-stable}"

echo "[claude-code] installing Claude Code (${CLAUDE_VERSION})"

ensure_pkg() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "[claude-code] installing build dependency: $2"
		apt-get update -y
		apt-get install -y --no-install-recommends "$2"
	fi
}

ensure_pkg curl curl

# The official installer writes into $HOME; run it under a throwaway HOME and
# then relocate the resulting binary to a system-wide location on PATH.
TMP_HOME="$(mktemp -d)"
cleanup() { rm -rf "${TMP_HOME}"; }
trap cleanup EXIT

# The installer drops a launcher symlink at $HOME/.local/bin/claude pointing
# into $HOME/.local/share/claude/versions/, so resolve it before copying.
HOME="${TMP_HOME}" bash -c "curl -fsSL https://claude.ai/install.sh | bash -s -- '${CLAUDE_VERSION}'"
CLAUDE_LAUNCHER="${TMP_HOME}/.local/bin/claude"
if [ ! -e "${CLAUDE_LAUNCHER}" ]; then
	CLAUDE_LAUNCHER="$(find "${TMP_HOME}" -name claude -type f -perm -u+x 2>/dev/null | head -1)"
fi
CLAUDE_BIN="$(readlink -f "${CLAUDE_LAUNCHER}")"
if [ -z "${CLAUDE_BIN}" ] || [ ! -f "${CLAUDE_BIN}" ]; then
	echo "[claude-code] could not locate the installed claude binary" >&2
	exit 1
fi
install -m 0755 "${CLAUDE_BIN}" /usr/local/bin/claude
echo "[claude-code] claude -> $(HOME="${TMP_HOME}" /usr/local/bin/claude --version 2>/dev/null || echo '?')"

echo "[claude-code] done."
