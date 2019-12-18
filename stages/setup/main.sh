#!/bin/bash

set -e
source "${GITHUB_WORKSPACE}/toolchain/utils/bash_utils.sh"

_main() {
    for SCRIPT in toolchain/stages/setup/setup.d/*.sh; do
        local LOGFILE=$(mktemp -d)/"$(basename ${SCRIPT})"
        source ${SCRIPT}

        echo -n "Installing ${NAME}... "
        _setup &> "${LOGFILE}"

        RETVAL=$?
        if ((${RETVAL} != 0)); then
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
