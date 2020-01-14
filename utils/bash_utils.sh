#!/bin/bash

# log() takes two parameters
# 1. The errorlevel as defined in $LEVELS. defaults to "INFO"
# 2. The log message
#
# If no errorlevel is provided as first argument errorlevel INFO will be used

while [[ -z ${TOOLCHAIN_PATH} ]]; do
  [[ -d 'toolchain' ]] && TOOLCHAIN_PATH='toolchain' || TOOLCHAIN_PATH='' && break
done
export TOOLCHAIN_PATH

log() {
    echo "$@"
}

_setup() {
    export log
    return 0
}
