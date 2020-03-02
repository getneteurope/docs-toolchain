# frozen_string_literal: true

require 'asciidoctor'
require 'fileutils'
require_relative '../config_manager.rb'
require_relative '../log/log.rb'
require_relative '../utils/paths.rb'

CM = Toolchain::ConfigManager.instance

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
    def self.build(build_dir = ::Toolchain.build_path, index: 'index.adoc')
      index_path = File.join(build_dir, index)
      raise IOError, "File #{index_path} does not exist" unless
        File.exist?(index_path)

      # call asciidoctor
      # FIXME hardcoded, extract attributes and read config file from content repo
      # or overwrite default attributes with a config file
      # NOTE Requires need to be required explicitly with require or require_relative
      # instead of being passed as options[:requires]
      stage_log(:build, 'HTML5 Multipage Backend loaded')
      require File.join(File.expand_path(::Toolchain.toolchain_path),
        'lib/adoc-extensions.d/multipage_html5.rb')
      options = {
        attributes: {
          'linkcss' => true,
          'multipage-level' => CM.get('asciidoc.multipage_level'),
          'stylesdir' => 'css',
          'stylesheet' => 'main.css',
          'icons' => 'font',
          'toc' => 'left',
          'systemtimestamp' => %x(date +%s),
          'backend' => 'multipage_html5',
          'docinfo' => 'shared',
          'root' => Toolchain.build_path
        },
        safe: :safe,
        failure_level: 'WARN'
      }
      Asciidoctor.convert_file(index_path, options)

      # create HTML folder
      html_dir = ::Toolchain.html_path
      mkdir(html_dir)

      # move web pages to html/
      htmls = Dir[File.join(build_dir, '*.html')].delete_if do |file|
        %w[docinfo toc].any? { |term| File.basename(file).start_with?(term) }
      end
      htmls.each do |html|
        FileUtils.mv(html, html_dir, force: true)
      end

      # move assets to html/
      assets = %w[css js fonts images icons]
      assets.each do |asset|
        stage_log(:build, "... Copying #{asset}")
        from_dir = File.join(build_dir, asset)
        next unless Dir.exist?(from_dir)
        to_dir = File.join(html_dir, asset)
        FileUtils.mv(from_dir, to_dir, force: true)
        # mkdir(to_dir)
        # Dir[File.join(from_dir, '*')].each do |file|
        #   FileUtils.mv(file, to_dir)
        # end
      end

      stage_log(:build, "Files are in #{html_dir}")
    end
  end
end
