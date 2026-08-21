#!/usr/bin/env bash
# Installs the opencode CLI into /usr/local/bin (available to every container user).
set -euo pipefail

OPENCODE_VERSION="${OPENCODEVERSION:-latest}"

echo "[opencode] installing opencode (${OPENCODE_VERSION})"

ensure_pkg() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "[opencode] installing build dependency: $2"
		apt-get update -y
		apt-get install -y --no-install-recommends "$2"
	fi
}

ensure_pkg curl curl
ensure_pkg unzip unzip

# The official installer writes into $HOME; run it under a throwaway HOME and
# then relocate the resulting binary to a system-wide location on PATH.
TMP_HOME="$(mktemp -d)"
cleanup() { rm -rf "${TMP_HOME}"; }
trap cleanup EXIT

if [ "${OPENCODE_VERSION}" = "latest" ]; then
	HOME="${TMP_HOME}" bash -c "curl -fsSL https://opencode.ai/install | bash"
else
	HOME="${TMP_HOME}" bash -c "curl -fsSL https://opencode.ai/install | bash -s -- --version '${OPENCODE_VERSION}'"
fi
install -m 0755 "${TMP_HOME}/.opencode/bin/opencode" /usr/local/bin/opencode
echo "[opencode] opencode -> $(/usr/local/bin/opencode --version 2>/dev/null || echo '?')"

echo "[opencode] done."
