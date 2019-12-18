#!/bin/bash

set -e
source "${GITHUB_WORKSPACE}/toolchain/utils/bash_utils.sh"

LOGDIR="/tmp/logs"
mkdir -p "$LOGDIR"
_main() {
    for SCRIPT in "${GITHUB_WORKSPACE}/toolchain/stages/setup/setup.d/"*.sh; do
        local LOGFILE="${LOGDIR}/$(basename "${SCRIPT}" .sh).txt"
        source "${SCRIPT}"

        echo -n "Installing ${NAME}... "
        _setup | tee "${LOGFILE}"

        RETVAL=$?
        if ((RETVAL != 0)); then
            echo "Failed!"
            echo "###"
            cat "${LOGFILE}"
            echo "###"
            return ${RETVAL}
        else
            echo "OK"
        fi
    done
}

_main
exit $?
