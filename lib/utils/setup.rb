# frozen_string_literal: true

require 'fileutils'
require_relative '../config_manager.rb'
require_relative '../utils/paths.rb'
require_relative '../log/log.rb'

module Toolchain
  # Module related to the setup of the build directory
  module Setup
    ##
    # Setup build directory.
    #
    # Params:
    # * +build_dir+ Build directory
    #               (default: ConfigManager[:build_dir] || +DEFAULT_BUILD_DIR+)
    # * +content+   Content directory (default: _content_)
    #
    # Raises error if directory does not exist.
    #
    # Returns nothing.
    #
    def self.setup(build_dir = ::Toolchain.build_path, content: 'content')
      FileUtils.mkdir_p(build_dir) unless Dir.exists?(build_dir)
      stage_log(:build, "setting up build dir @ #{build_dir}")
      content_path = File.join(::Toolchain.content_path, content)
      unless Dir.exist?(content_path)
        error("Directory '#{content_path}' does not exist")
        raise "Directory '#{content_path}' does not exist"
      end

      status = system("cp -r #{content_path}/* #{build_dir}")
      raise "Could not cp #{content_path}/* to #{build_dir}" unless status
    end
  end
end
