#!/bin/bash

set -e
source "${TOOLCHAIN_PATH}utils/bash_utils.sh"

LOGDIR="/tmp/logs"
mkdir -p "${LOGDIR}"
_main() {
    for SCRIPT in "${TOOLCHAIN_PATH}stages/setup/setup.d/"*.sh; do
        local LOGFILE="${LOGDIR}/$(basename "${SCRIPT}" .sh).txt"
        source "${SCRIPT}"

        log "Installing ${NAME}... "
        _setup | tee "${LOGFILE}"

        RETVAL=$?
        if ((RETVAL != 0)); then
            log ERROR "Failed!"
            log "$(cat ${LOGFILE})"
            return ${RETVAL}
        else
            log "OK"
        fi
    done
}

_main
exit $?
