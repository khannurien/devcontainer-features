#!/bin/bash
set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "claude on PATH" bash -c "command -v claude"
check "claude runs" claude --version
check "rtk on PATH" bash -c "command -v rtk"
check "rtk runs" rtk --version

reportResults
