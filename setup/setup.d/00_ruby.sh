#!/bin/bash

NAME="Ruby gems"
export NAME

_setup() {
    gem install bundler
    gem install specific_install
    gem specific_install -l https://github.com/ldz-w/asciidoctor-diagram -b master
    bundle install --gemfile="${TOOLCHAIN_PATH}/setup/Gemfiles.rb"
    return $?
}
