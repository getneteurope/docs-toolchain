# frozen_string_literal: true

require_relative '../config_manager.rb'

# Toolchain module
module Toolchain
  ##
  # content_path
  # Returns path to content directory root.
  #
  def self.content_path
    content_dir = Dir.pwd
    dir = File.basename(Dir.pwd)
    content_dir = dir if dir == 'toolchain'

    %w[GITHUB_WORKSPACE CONTENT_PATH].each do |envvar|
      content_dir = ENV[envvar] if ENV.key?(envvar)
    end
    return content_dir
  end

  ##
  # document_root
  # Returns the root of content structure, i.e. where +index.adoc+ is located.
  #
  def self.document_root
    return ENV['DOCUMENT_ROOT'] if ENV.key?('DOCUMENT_ROOT')
    return File.join(content_path, 'content')
  end

  ##
  # toolchain_path
  # Returns path to toolchain root.
  #
  def self.toolchain_path
    toolchain_dir = File.join(Dir.pwd, 'toolchain')
    toolchain_dir = Dir.pwd unless Dir.exist?(toolchain_dir)
    toolchain_dir = ENV['TOOLCHAIN_PATH'] if ENV.key?('TOOLCHAIN_PATH')
    return toolchain_dir
  end

  ##
  # build_path
  # Returns path to toolchain build directory.
  #
  def self.build_path
    return ENV['BUILD_PATH'] if ENV.key?('BUILD_PATH')
    return ConfigManager.instance.get('build.dir')
  end

  ##
  # html_path
  # Returns path to generated html files.
  #
  def self.html_path
    return ENV['HTML_DIR'] if ENV.key?('HTML_DIR')
    return ConfigManager.instance.get('build.html.dir')
  end

  ##
  # custom_dir
  # Returns the custom/ directory, which holds custom extensions and processes
  # in the content repository.
  #
  def self.custom_dir
    return ENV['CUSTOM_DIR'] if ENV.key?('CUSTOM_DIR')
    return File.join(content_path,
      ConfigManager.instance.get('custom.dir') || '')
  end
end
