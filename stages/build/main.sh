#!/bin/bash

BUILD_PATH="/tmp/build"

_setup() {
    log INFO "Build path is: $BUILD_PATH"
    mkdir -p "$BUILD_PATH"
    cp -r content/ "$BUILD_PATH"
}

_build() {
    asciidoctor --failure-level=WARN \
        -a linkcss \
        -a icons=font -a toc=left -a systemtimestamp="$(date +%s)" \
        index.adoc
        # -a linkcss -a stylesheet=main.css -a stylesdir=css \
}

_setup
_build