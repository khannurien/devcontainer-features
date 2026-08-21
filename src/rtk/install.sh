#!/usr/bin/env bash
# Installs rtk into /usr/local/bin (available to every container user) and
# optionally wires it into the coding agents installed in the container.
set -euo pipefail

RTK_VERSION_OPT="${RTKVERSION:-latest}"
INIT="${INIT:-auto}"

# Provided by the dev container build for the user the container runs as.
USERNAME="${_REMOTE_USER:-root}"
USER_HOME="${_REMOTE_USER_HOME:-/root}"

echo "[rtk] remote user: ${USERNAME} (${USER_HOME})"

ensure_pkg() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "[rtk] installing build dependency: $2"
		apt-get update -y
		apt-get install -y --no-install-recommends "$2"
	fi
}

ensure_pkg curl curl
ensure_pkg tar tar

# The official installer writes into $HOME; run it under a throwaway HOME and
# then relocate the resulting binary to a system-wide location on PATH.
TMP_HOME="$(mktemp -d)"
cleanup() { rm -rf "${TMP_HOME}"; }
trap cleanup EXIT

echo "[rtk] installing rtk (${RTK_VERSION_OPT})"
if [ "${RTK_VERSION_OPT}" = "latest" ]; then
	HOME="${TMP_HOME}" sh -c "curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"
else
	HOME="${TMP_HOME}" RTK_VERSION="${RTK_VERSION_OPT}" sh -c "curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"
fi
RTK_BIN="${TMP_HOME}/.local/bin/rtk"
if [ ! -f "${RTK_BIN}" ]; then
	RTK_BIN="$(find "${TMP_HOME}" -name rtk -type f 2>/dev/null | head -1)"
fi
install -m 0755 "${RTK_BIN}" /usr/local/bin/rtk
echo "[rtk] rtk -> $(/usr/local/bin/rtk --version 2>/dev/null || echo '?')"

# --- agent wiring ---------------------------------------------------------
# 'rtk init -g' writes RTK.md plus the PreToolUse hook in ~/.claude/settings.json;
# adding --opencode also installs the opencode plugin. Three things are needed to
# make it work unattended: the agent's config directory must already exist (rtk
# does not create it and exits 1 if it is missing), --auto-patch to patch
# settings.json without prompting, and a --*-trust-filters answer so a detected
# custom filter cannot block the build on a prompt. Filter trust that matters is
# the host's, and travels with the rtk-host-config Feature at runtime.
#
# Note that a bind-mounted host config (see the *-host-config Features) shadows
# whatever is written here, which is usually what you want.
run_as_user() {
	if [ "${USERNAME}" = "root" ]; then
		HOME="${USER_HOME}" "$@"
	else
		su "${USERNAME}" -c "HOME='${USER_HOME}' $*"
	fi
}

prepare_dir() {
	mkdir -p "$1"
	chown "${USERNAME}" "$1" 2>/dev/null || true
}

init_claude=false
init_opencode=false
case "${INIT}" in
	none) ;;
	claude-code) init_claude=true ;;
	opencode)    init_opencode=true ;;
	both)        init_claude=true; init_opencode=true ;;
	auto)
		command -v claude   >/dev/null 2>&1 && init_claude=true
		command -v opencode >/dev/null 2>&1 && init_opencode=true
		;;
	*)
		echo "[rtk] unknown init value '${INIT}', treating as 'none'" >&2
		;;
esac

# 'rtk init --opencode' means "opencode in addition to Claude Code", so a single
# invocation covers both and there is no opencode-only mode.
if [ "${init_opencode}" = true ]; then
	echo "[rtk] wiring rtk into opencode (and Claude Code) for ${USERNAME}"
	prepare_dir "${USER_HOME}/.claude"
	prepare_dir "${USER_HOME}/.config/opencode"
	run_as_user /usr/local/bin/rtk init -g --opencode --auto-patch --no-trust-filters \
		|| echo "[rtk] rtk init failed (non-fatal)"
elif [ "${init_claude}" = true ]; then
	echo "[rtk] wiring rtk into Claude Code for ${USERNAME}"
	prepare_dir "${USER_HOME}/.claude"
	run_as_user /usr/local/bin/rtk init -g --auto-patch --no-trust-filters \
		|| echo "[rtk] rtk init failed (non-fatal)"
else
	echo "[rtk] no agent wiring (init=${INIT})"
fi

echo "[rtk] done."
