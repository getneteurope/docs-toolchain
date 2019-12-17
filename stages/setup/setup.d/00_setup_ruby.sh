#!/bin/bash

NAME="Ruby gems"

_setup() {
    gem install bundler
    gem install specific_install
    gem specific_install -l https://github.com/ldz-w/asciidoctor-diagram -b master
    bundle install --gemfile=utils/bundle_combined_gemfiles.rb
    return $?
}
