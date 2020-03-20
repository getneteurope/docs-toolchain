#!/bin/bash

NAME="NodeJS modules"
export NAME

DISABLE="true"
export DISABLE

_setup() {
    export PATH="node_modules/.bin:${PATH}"
    npm install package-json-merge
    local PJ="${TOOLCHAIN_PATH}/dependencies/package.json dependencies/package.json"
    local PJ_FILES
    for F in ${PJ}; do
        if [[ -r ${F} ]]; then
            PJ_FILES="${PJ_FILES} ${F}"
        fi
    done
    package-json-merge ${PJ_FILES} > package.json
    npm install
    return $?
}
