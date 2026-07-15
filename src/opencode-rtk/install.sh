#!/usr/bin/env bash
# Installs opencode + rtk into /usr/local/bin (available to every container user)
# and optionally wires rtk into opencode for the remote user.
set -euo pipefail

# Feature options arrive as uppercased env vars matching the option ids.
OPENCODE_VERSION="${OPENCODEVERSION:-latest}"
INSTALL_RTK="${INSTALLRTK:-true}"
RTK_INIT_OPENCODE="${RTKINITOPENCODE:-true}"

# Provided by the dev container build for the user the container runs as.
USERNAME="${_REMOTE_USER:-root}"
USER_HOME="${_REMOTE_USER_HOME:-/root}"

echo "[opencode-rtk] remote user: ${USERNAME} (${USER_HOME})"

ensure_pkg() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "[opencode-rtk] installing build dependency: $2"
		apt-get update -y
		apt-get install -y --no-install-recommends "$2"
	fi
}

ensure_pkg curl curl
ensure_pkg unzip unzip
ensure_pkg tar tar

# The official installers write into $HOME; run them under a throwaway HOME and
# then relocate the resulting binaries to a system-wide location on PATH.
TMP_HOME="$(mktemp -d)"
cleanup() { rm -rf "${TMP_HOME}"; }
trap cleanup EXIT

# --- opencode -------------------------------------------------------------
echo "[opencode-rtk] installing opencode (${OPENCODE_VERSION})"
if [ "${OPENCODE_VERSION}" = "latest" ]; then
	HOME="${TMP_HOME}" bash -c "curl -fsSL https://opencode.ai/install | bash"
else
	HOME="${TMP_HOME}" bash -c "curl -fsSL https://opencode.ai/install | bash -s -- --version '${OPENCODE_VERSION}'"
fi
install -m 0755 "${TMP_HOME}/.opencode/bin/opencode" /usr/local/bin/opencode
echo "[opencode-rtk] opencode -> $(/usr/local/bin/opencode --version 2>/dev/null || echo '?')"

# --- rtk ------------------------------------------------------------------
if [ "${INSTALL_RTK}" = "true" ]; then
	echo "[opencode-rtk] installing rtk"
	HOME="${TMP_HOME}" sh -c "curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"
	RTK_BIN="${TMP_HOME}/.local/bin/rtk"
	if [ ! -f "${RTK_BIN}" ]; then
		RTK_BIN="$(find "${TMP_HOME}" -name rtk -type f 2>/dev/null | head -1)"
	fi
	install -m 0755 "${RTK_BIN}" /usr/local/bin/rtk
	echo "[opencode-rtk] rtk -> $(/usr/local/bin/rtk --version 2>/dev/null || echo '?')"

	if [ "${RTK_INIT_OPENCODE}" = "true" ]; then
		echo "[opencode-rtk] running 'rtk init -g --opencode' for ${USERNAME}"
		if [ "${USERNAME}" = "root" ]; then
			HOME="${USER_HOME}" /usr/local/bin/rtk init -g --opencode || echo "[opencode-rtk] rtk init failed (non-fatal)"
		else
			su "${USERNAME}" -c "HOME='${USER_HOME}' /usr/local/bin/rtk init -g --opencode" || echo "[opencode-rtk] rtk init failed (non-fatal)"
		fi
	fi
fi

echo "[opencode-rtk] done."
