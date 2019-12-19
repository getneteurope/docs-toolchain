#!/bin/bash

set -e
source "${TOOLCHAIN_PATH}utils/bash_utils.sh"

BUILD_PATH="/tmp/build"

_setup() {
    log INFO "Build path is: $BUILD_PATH"
    mkdir -p "$BUILD_PATH"
    cp -r content/* "$BUILD_PATH"
}

_build() {
    pushd "$BUILD_PATH" >/dev/null
    asciidoctor --failure-level=WARN \
        -a linkcss -a stylesdir=css \
        -a icons=font -a toc=left -a systemtimestamp="$(date +%s)" \
        index.adoc
        # -a linkcss -a stylesheet=main.css -a stylesdir=css \
    
    mkdir -p html
    mv ./*.html css/ html/
    # TODO: add CSS and JS folders
    popd >/dev/null
}

_setup
_build