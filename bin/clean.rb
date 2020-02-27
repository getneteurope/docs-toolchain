# frozen_string_literal: true

require 'fileutils'
require_relative '../lib/config_manager.rb'
require_relative '../lib/log/log.rb'
require_relative '../lib/utils/paths.rb'

build_dir = Toolchain.build_path
stage_log(:clean, "Running clean on #{build_dir}")
FileUtils.rm_rf(build_dir)
