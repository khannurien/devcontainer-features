#!/usr/bin/env bash
# Links the bind-mounted host Claude Code / rtk config into the remote user's
# home. The mounts themselves are declared in devcontainer-feature.json; they
# land under /claude-host because a Feature cannot know the remote user's home
# at mount time. This script bridges that gap with symlinks.
#
# Only ~/.claude is a real shared directory. Claude Code rewrites its state file
# atomically (write a temporary file, rename it over the target), which replaces
# the inode — and a Docker bind mount of a *file* pins the inode it was created
# with. So a bind-mounted ~/.claude.json goes stale the moment the host rewrites
# it: the container keeps writing to an unlinked inode (nlink 0) and nothing
# reaches the host. CLAUDE_CONFIG_DIR moves that file inside the mounted
# directory instead, where the rename lands on the host for real.
set -euo pipefail

USERNAME="${_REMOTE_USER:-root}"
USER_HOME="${_REMOTE_USER_HOME:-/root}"
CONFIG_DIR=/claude-host/claude

echo "[claude-host-config] remote user: ${USERNAME} (${USER_HOME})"

# Mount points, so the bind targets exist in the image rather than being
# conjured as root-owned directories at container creation.
mkdir -p "${CONFIG_DIR}"
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

link "${CONFIG_DIR}" "${USER_HOME}/.claude"
# A symlink, unlike a bind mount, is resolved at every open, so it keeps
# tracking the state file across the atomic renames. Kept for anything that
# still reads ~/.claude.json by hand rather than honouring CLAUDE_CONFIG_DIR.
link "${CONFIG_DIR}/.claude.json" "${USER_HOME}/.claude.json"

# Lifecycle hook: the mounts only exist once the container runs, so the state
# file can only be seeded then.
install -d /usr/local/share/claude-host-config
cat > /usr/local/share/claude-host-config/seed.sh <<'SEED'
#!/usr/bin/env bash
# postStartCommand: seed the shared state file once, from the host's own
# ~/.claude.json, so the first session in a fresh container starts already
# onboarded and signed in instead of at the theme picker. Afterwards the
# container owns the file and the seed mount is ignored.
set -euo pipefail

CONFIG_DIR="${CLAUDE_CONFIG_DIR:-/claude-host/claude}"
STATE="${CONFIG_DIR}/.claude.json"
SEED_FILE=/claude-host/claude.json

if [ -s "${STATE}" ]; then
	exit 0
fi

mkdir -p "${CONFIG_DIR}"
if [ -f "${SEED_FILE}" ] && [ -s "${SEED_FILE}" ]; then
	cp "${SEED_FILE}" "${STATE}"
	echo "[claude-host-config] seeded ${STATE} from the host's ~/.claude.json"
else
	printf '{"hasCompletedOnboarding":true}\n' > "${STATE}"
	echo "[claude-host-config] created ${STATE}"
fi
SEED
chmod 0755 /usr/local/share/claude-host-config/seed.sh

echo "[claude-host-config] CLAUDE_CONFIG_DIR=${CONFIG_DIR}"
echo "[claude-host-config] done."
