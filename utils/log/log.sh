#!/bin/bash

#  Simple log util
#  Can be sourced in bash script or used standalone
#  by Wirecard CEE TecDoc

[[ "${BASH_SOURCE[0]}" != "${0}" ]] && SOURCED=true;

LEVELS=('DEBUG' 'INFO' 'WARN' 'ERROR')
usage() {
    echo "$(basename ${0}) logging util"
    echo
    echo "Usage standalone:"
    echo "  ./$(basename ${0}) --caller calling_script.js --line 123 LOGLEVEL Message Text Here"
    echo
    echo "Usage in Bash scripts:"
    echo "  source $(basename ${0})"
    echo "  log LOGLEVEL message_text"
    echo
    echo "LOGLEVEL can be one of ${LEVELS[*]}. If not provided defaults to INFO."
}

log() {
  local ERROR_LEVEL=INFO # if no LEVEL provided treat it as INFO
  if [[ " ${LEVELS[@]} " =~ " ${1} " ]]; then
    ERROR_LEVEL=${1}
    shift
  fi
  local MSG_TEXT="${@}"
  local UNIX_TIMESTAMP="$(date +%s)"
  local TIMESTAMP_FORMAT="%H:%M:%S"
  local TIMESTAMP_STRING=$(date -d @${UNIX_TIMESTAMP} +"${TIMESTAMP_FORMAT}" 2>/dev/null)
  #MacOS workaround for local builds
  [[ -n ${TIMESTAMP_STRING} ]] || TIMESTAMP_STRING=$(date -r ${UNIX_TIMESTAMP} +"${TIMESTAMP_FORMAT}")

  local CALLER_INFO=($(caller))

  # if not sourced but called directly, caller and line number must be passed as args
  if [[ -z ${CALLER} ]]; then
    local CALLER=$(basename ${CALLER_INFO[1]})
    local LINENR=${CALLER_INFO[0]}
  fi
  if [[ ${ERROR_LEVEL} != 'DEBUG' || ${DEBUG} == 'true' ]]; then
    >&2 echo "[${TIMESTAMP_STRING}] ${ERROR_LEVEL} ${CALLER}:${LINENR} ${MSG_TEXT}"
  fi

  #if LOG_NOJSON is set (e.g. during setup), do not use log_append.js and return early
  [[ ${LOG_NOJSON} == 'true' ]] && return 0
  
  echo "${MSG_TEXT}" | node ${TOOLCHAIN_PATH}utils/log/log_append.js \
    --timestamp="${UNIX_TIMESTAMP}" --errorlevel="${ERROR_LEVEL}" --caller="${CALLER}" --line="${LINENR}"
    
  return $?
}

if [[ -z ${SOURCED} ]]; then
    while true; do
        case "$1" in
            -h|--help)
            usage
            exit 1
            ;;
            -l|--line)
            LINENR="${2}"
            shift
            ;;
            -c|--caller)
            CALLER="${2}"
            shift
            ;;
            *)
            break
            ;;
        esac
        shift
    done

    if [[ -z ${CALLER} ]] || [[ -z ${LINENR} ]]; then 
        usage
        exit 1
    fi

    log $@
    exit $?
fi

return 0
