#!/bin/bash

[[ -d toolchain/stages ]] && export TOOLCHAIN_PATH="$(pwd)/toolchain/"

echo "Setup"
_main() {
    for SCRIPT in ${TOOLCHAIN_PATH}stages/setup/setup.d/*setup_*.sh; do
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
