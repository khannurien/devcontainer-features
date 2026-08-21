#!/bin/bash
set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "~/.config/rtk is a symlink" bash -c "[ -L \"\$HOME/.config/rtk\" ]"
check "~/.config/rtk points at the mount" bash -c "[ \"\$(readlink \"\$HOME/.config/rtk\")\" = /rtk-host/config ]"
check "mount is present" bash -c "mount | grep -q /rtk-host/config"

reportResults
