#!/bin/bash

set -e

source "${TOOLCHAIN_PATH}/utils/bash_utils.sh"

log "Post script"
node "${TOOLCHAIN_PATH}/utils/log/log_parser.js"

exit 0
