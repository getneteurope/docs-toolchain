#!/bin/bash

# log() takes two parameters
# 1. The errorlevel as defined in $LEVELS. defaults to "INFO"
# 2. The log message
#
# Messages with errorlevel DEBUG will only be logged for env DEBUG=true
# If no errorlevel is provided as first argument errorlevel INFO will be used
log() {
  local LEVELS=('DEBUG' 'INFO' 'WARN' 'ERROR')

  local ERROR_LEVEL=INFO # if no LEVEL provided treat it as INFO
  if [[ " ${LEVELS[@]} " =~ " ${1} " ]]; then
    ERROR_LEVEL=${1}
    shift
  fi
  local MSG_TEXT="${@}"
  local UNIX_TIMESTAMP="$(date +%s)"
  local TIMESTAMP_FORMAT="%H:%M:%S,%3N"
  local TIMESTAMP_STRING=$(date -d @${UNIX_TIMESTAMP} +"${TIMESTAMP_FORMAT}")
  local CALLER_INFO=($(caller))
  local CALLER=$(basename ${CALLER_INFO[1]})
  local LINENR=${CALLER_INFO[0]}

  if [[ ${ERROR_LEVEL} != 'DEBUG' || ${DEBUG} == 'true' ]]; then
    >&2 echo "[${TIMESTAMP_STRING}] ${CALLER}:${LINENR} ${ERROR_LEVEL} ${MSG_TEXT}"
  fi
  echo "${MSG_TEXT}" | node "toolchain/utils/append_to_log.js" \
    --timestamp="${UNIX_TIMESTAMP}" --errorlevel="${ERROR_LEVEL}" --caller="${CALLER}" --line="${CALLER_LINENR}"
  return $?
}

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
