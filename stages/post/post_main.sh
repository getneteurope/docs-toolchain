#!/bin/bash

set -e

source "${TOOLCHAIN_PATH}utils/bash_utils.sh"

echo "Post script"
node "${TOOLCHAIN_PATH}utils/log/log_parser.js"

exit 0
