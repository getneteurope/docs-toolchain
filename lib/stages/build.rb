# frozen_string_literal: true

require 'asciidoctor'
require 'fileutils'
require_relative '../utils.rb'

##
# mkdir
#
# Create +path+ if +path+ does not exist.
# Returns nothing.
def mkdir(path)
  Dir.mkdir(path) unless Dir.exist?(path)
end

##
# Toolchain module
#
module Toolchain
  ##
  # Build module
  # Relevant modlues/classes/functions for the Build stage
  module Build
    # default build directory
    DEFAULT_BUILD_DIR = '/tmp/build'

    ##
    # Setup build directory.
    #
    # Params:
    # * +build_dir+ Build directory (default: +DEFAULT_BUILD_DIR+)
    # * +content+   Content directory (default: _content_)
    #
    # Raises error if directory does not exist.
    #
    # Returns nothing.
    #
    def self.setup(build_dir = DEFAULT_BUILD_DIR, content: 'content')
      raise "Directory '#{content}' does not exist" unless Dir.exist?(content.to_s)

      mkdir(build_dir)
      status = system("cp -r #{content}/* #{build_dir}")
      raise "Could not cp #{content}/* to #{build_dir}" unless status
    end

    ##
    # Build phase
    #
    # Build the HTML in +build_dir+ with +index+ as index file.
    # Default:
    # * +build_dir+ = +DEFAULT_BUILD_DIR+
    # * +index+ = _index.adoc_
    #
    # Generated files are placed in _+build_dir+/html_
    #
    # Raises exception if file or directory not found.
    #
    # Returns nil.
    #
    def self.build(build_dir = DEFAULT_BUILD_DIR, index: 'index.adoc')
      index_path = File.join(build_dir, index)
      raise IOError, "File #{index_path} does not exist" unless
        File.exist?(index_path)

      # call asciidoctor
      # FIXME hardcoded, extract attributes and read config file from content repo
      # or overwrite default attributes with a config file
      options = {
        requires: %w[],
        attributes: {
          'linkcss' => true,
          'stylesdir' => 'css',
          'stylesheet' => 'main.css',
          'icons' => 'font',
          'toc' => 'left',
          'systemtimestamp' => %x(date +%s)
        },
        safe: :safe,
        failure_level: 'WARN'
      }
      Asciidoctor.convert_file(index_path, options)
      # doc = Asciidoctor.load_file(index_path, options)
      # doc.convert

      # move web resources to html/
      html_dir = File.join(build_dir, 'html')
      mkdir(html_dir)

      index_html = "#{File.basename(index, '.adoc')}.html"
      files_to_copy = %w[css js]
      files_to_copy << index_html
      files_to_copy.each do |file|
        file = File.join(build_dir, file)
        FileUtils.mv(file, html_dir, force: true) if File.exist?(file)
      end
      stage_log(:build, "Files are in #{html_dir}")
    end
  end
end
