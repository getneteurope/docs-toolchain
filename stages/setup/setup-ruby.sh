#!/bin/bash

_setup_ruby() {
    ruby setup/install_gems.rb
    return $?
}