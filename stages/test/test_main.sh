#!/bin/bash

set -e
source "${TOOLCHAIN_PATH}/utils/bash_utils.sh"

rake -f "${TOOLCHAIN_PATH}/Rakefile" build
