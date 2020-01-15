#!/bin/bash

set -e
source "${TOOLCHAIN_PATH}/utils/bash_utils.sh"

LOGDIR="/tmp/logs"
mkdir -p "${LOGDIR}"
export LOG_NOJSON=true #log_append cannot use log_append during setup phase

_main() {
    for SCRIPT in "${TOOLCHAIN_PATH}/setup/setup.d/"*.sh; do
        local LOGFILE="${LOGDIR}/$(basename "${SCRIPT}" .sh).txt"
        source "${SCRIPT}"

        if [[ -z $DISABLE ]]; then
            log "Installing ${NAME}... "
            _setup | tee "${LOGFILE}"
        else
            log "Skipping ${NAME}..."
            log "Reason: disabled"
        fi

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
