#!/bin/bash
set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "opencode on PATH" bash -c "command -v opencode"
check "opencode runs" opencode --version

reportResults
