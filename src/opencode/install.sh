#!/usr/bin/env bash
# Installs the opencode CLI for the remote user, in the layout its own upgrader
# expects.
#
# opencode is not relocatable: its installer hardcodes
# INSTALL_DIR=$HOME/.opencode/bin, with no option or environment variable to
# point it elsewhere. A copy of the binary parked in /usr/local/bin therefore
# cannot be upgraded in place. Worse, 'opencode upgrade' notices it, warns that
# opencode "is installed to /usr/local/bin/opencode and may be managed by a
# package manager", and stops on an "Install anyways?" prompt — which hangs
# outright in a non-interactive shell. Answering yes installs a *second*
# opencode under $HOME, and which one runs then depends on PATH order.
#
# Installing where the upgrader already writes keeps a single opencode in the
# container. /usr/local/bin/opencode stays, as a symlink to that one install, so
# it can never be the stale one.
set -euo pipefail

OPENCODE_VERSION="${OPENCODEVERSION:-latest}"

# Provided by the dev container build for the user the container runs as.
USERNAME="${_REMOTE_USER:-root}"
USER_HOME="${_REMOTE_USER_HOME:-/root}"

echo "[opencode] remote user: ${USERNAME} (${USER_HOME})"
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

# Running the official installer as the remote user is what puts the binary in
# that user's home, where 'opencode upgrade' will later replace it. The
# installer also appends its own PATH line to the user's shell rc files.
{
	echo '#!/usr/bin/env bash'
	echo 'set -euo pipefail'
	if [ "${OPENCODE_VERSION}" = "latest" ]; then
		echo "curl -fsSL https://opencode.ai/install | bash"
	else
		echo "curl -fsSL https://opencode.ai/install | bash -s -- --version '${OPENCODE_VERSION}'"
	fi
} > "${TMP_DIR}/install-opencode.sh"
run_script_as_user "${TMP_DIR}/install-opencode.sh"

OPENCODE_BIN="${USER_HOME}/.opencode/bin/opencode"
if [ ! -e "${OPENCODE_BIN}" ]; then
	echo "[opencode] the installer did not leave a binary at ${OPENCODE_BIN}" >&2
	exit 1
fi

# The installer's own rc edits only cover interactive shells, and only the ones
# whose rc file it recognised. profile.d covers login shells on top of that.
cat > /etc/profile.d/opencode.sh <<'PROFILE'
# opencode lives under $HOME/.opencode/bin — that is where its upgrader writes
# new versions — so that directory has to be on PATH for it to be found.
case ":${PATH}:" in
	*":${HOME}/.opencode/bin:"*) ;;
	*) PATH="${HOME}/.opencode/bin:${PATH}" ;;
esac
export PATH
PROFILE
chmod 0644 /etc/profile.d/opencode.sh

for rc in "${USER_HOME}/.bashrc" "${USER_HOME}/.zshrc"; do
	[ -f "${rc}" ] || continue
	grep -q 'profile.d/opencode.sh' "${rc}" && continue
	cat >> "${rc}" <<'RC'

# opencode Feature: keep $HOME/.opencode/bin on PATH.
[ -f /etc/profile.d/opencode.sh ] && . /etc/profile.d/opencode.sh
RC
	chown "${USERNAME}" "${rc}" 2>/dev/null || true
done

# A shell that reads neither profile nor rc files and gets no environment probe
# (a `sh -c` from a devcontainer.json lifecycle command with userEnvProbe:none,
# say) still only has the default PATH. Bridge that with a symlink rather than a
# copy: it resolves to whatever version is installed now, so it cannot drift out
# of date the way the old /usr/local/bin copy did.
ln -sfn "${OPENCODE_BIN}" /usr/local/bin/opencode

cat > "${TMP_DIR}/opencode-version.sh" <<VERSION
#!/usr/bin/env bash
exec '${OPENCODE_BIN}' --version
VERSION
echo "[opencode] opencode -> $(run_script_as_user "${TMP_DIR}/opencode-version.sh" 2>/dev/null || echo '?')"
echo "[opencode] binary: ${OPENCODE_BIN}"

echo "[opencode] done."
