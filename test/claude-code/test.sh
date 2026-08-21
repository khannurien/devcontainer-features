#!/bin/bash
set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "claude on PATH" bash -c "command -v claude"
check "claude runs" claude --version

reportResults
