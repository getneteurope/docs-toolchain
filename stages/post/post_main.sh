#!/bin/bash

set -e
source "${GITHUB_WORKSPACE}/toolchain/utils/bash_utils.sh"

echo "Post script"
node "${GITHUB_WORKSPACE}toolchain/utils/log/log_parser.js"
