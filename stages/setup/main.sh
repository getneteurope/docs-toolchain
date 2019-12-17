#!/bin/bash

echo "Setup script"

echo "Setup ruby"
source setup/setup-ruby.sh
_setup_ruby

return $?
