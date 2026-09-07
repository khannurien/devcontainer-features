#!/usr/bin/env bash
# Installs the Claude Code CLI for the remote user, in the layout its own
# updater expects.
#
# Claude Code is not relocatable. 'claude install' and the background
# auto-updater both write to fixed, $HOME-anchored paths — a version tree under
# $HOME/.local/share/claude/versions/ and a launcher symlink at
# $HOME/.local/bin/claude — and there is no option or environment variable to
# point them anywhere else. So a copy of the binary parked in /usr/local/bin
# cannot be updated in place: the first 'claude install' or auto-update in the
# container installs a *second* claude under $HOME, and which one runs then
# depends on PATH order, which usually favours the stale system copy.
#
# Installing where the updater already writes keeps a single claude in the
# container. /usr/local/bin/claude stays, as a symlink to that one install, so
# it can never be the stale one.
set -euo pipefail

CLAUDE_VERSION="${CLAUDEVERSION:-stable}"

# Provided by the dev container build for the user the container runs as.
USERNAME="${_REMOTE_USER:-root}"
USER_HOME="${_REMOTE_USER_HOME:-/root}"

echo "[claude-code] remote user: ${USERNAME} (${USER_HOME})"
echo "[claude-code] installing Claude Code (${CLAUDE_VERSION})"

ensure_pkg() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "[claude-code] installing build dependency: $2"
		apt-get update -y
		apt-get install -y --no-install-recommends "$2"
	fi
}

ensure_pkg curl curl

# 'su -c' takes a single shell string, so anything with quoting or a pipe in it
# goes through a script file rather than being flattened into that string.
run_script_as_user() {
	local script="$1"
	chmod 0755 "${script}"
	if [ "${USERNAME}" = "root" ]; then
		HOME="${USER_HOME}" "${script}"
	else
		su "${USERNAME}" -c "HOME='${USER_HOME}' '${script}'"
	fi
}

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT
chmod 0755 "${TMP_DIR}"

# The official installer downloads a temporary binary and then runs
# 'claude install <target>' with it, which is the same code path as a later
# self-update. Running it as the remote user is what puts the version tree and
# the launcher in that user's home. It refuses to run as root when SUDO_USER is
# set; 'su' does not set SUDO_USER, so this stays out of that guard.
cat > "${TMP_DIR}/install-claude.sh" <<INSTALLER
#!/usr/bin/env bash
set -euo pipefail
curl -fsSL https://claude.ai/install.sh | bash -s -- '${CLAUDE_VERSION}'
INSTALLER
run_script_as_user "${TMP_DIR}/install-claude.sh"

CLAUDE_LAUNCHER="${USER_HOME}/.local/bin/claude"
if [ ! -e "${CLAUDE_LAUNCHER}" ]; then
	echo "[claude-code] the installer did not leave a launcher at ${CLAUDE_LAUNCHER}" >&2
	exit 1
fi

# $HOME/.local/bin is on PATH only for login shells on most base images, and
# only when it already existed when the shell started. Neither holds for the
# shells a dev container spawns, so put it there explicitly. profile.d covers
# login shells; the rc files cover interactive ones.
cat > /etc/profile.d/claude-code.sh <<'PROFILE'
# Claude Code lives under $HOME/.local — that is where its updater writes new
# versions — so that directory has to be on PATH for the launcher to be found.
case ":${PATH}:" in
	*":${HOME}/.local/bin:"*) ;;
	*) PATH="${HOME}/.local/bin:${PATH}" ;;
esac
export PATH
PROFILE
chmod 0644 /etc/profile.d/claude-code.sh

for rc in "${USER_HOME}/.bashrc" "${USER_HOME}/.zshrc"; do
	[ -f "${rc}" ] || continue
	grep -q 'profile.d/claude-code.sh' "${rc}" && continue
	cat >> "${rc}" <<'RC'

# claude-code Feature: keep $HOME/.local/bin (the Claude Code launcher) on PATH.
[ -f /etc/profile.d/claude-code.sh ] && . /etc/profile.d/claude-code.sh
RC
	chown "${USERNAME}" "${rc}" 2>/dev/null || true
done

# A shell that reads neither profile nor rc files and gets no environment probe
# (a `sh -c` from a devcontainer.json lifecycle command with userEnvProbe:none,
# say) still only has the default PATH. Bridge that with a symlink rather than a
# copy: it resolves through the user's launcher to whatever version is installed
# now, so it cannot drift out of date the way the old /usr/local/bin copy did.
ln -sfn "${CLAUDE_LAUNCHER}" /usr/local/bin/claude

cat > "${TMP_DIR}/claude-version.sh" <<VERSION
#!/usr/bin/env bash
exec '${CLAUDE_LAUNCHER}' --version
VERSION
echo "[claude-code] claude -> $(run_script_as_user "${TMP_DIR}/claude-version.sh" 2>/dev/null || echo '?')"
echo "[claude-code] launcher: ${CLAUDE_LAUNCHER} -> $(readlink -f "${CLAUDE_LAUNCHER}")"

echo "[claude-code] done."
