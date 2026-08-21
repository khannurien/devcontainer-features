#!/bin/bash
set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "rtk on PATH" bash -c "command -v rtk"
check "rtk runs" rtk --version
# No agent is installed in this image, so 'init: auto' should wire up nothing.
check "rtk gain works" bash -c "rtk gain >/dev/null"

reportResults
