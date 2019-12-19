#!/bin/bash

# log() takes two parameters
# 1. The errorlevel as defined in $LEVELS. defaults to "INFO"
# 2. The log message
#
# Messages with errorlevel DEBUG will only be logged for env DEBUG=true
# If no errorlevel is provided as first argument errorlevel INFO will be used

source ${TOOLCHAIN_PATH}utils/log/log.sh

_test() {
  log DEBUG "nur wenn DEBUG=true gesetzt ist"
  log "ohne angabe eines error levels auch ein info"
  log INFO "eine info mit komplexem text $(ls -l)"
  log ERROR "ein error kommt in output und errors.json"
}

_setup() {
    export log
    return 0
}
