# frozen_string_literal: true

require 'asciidoctor'
require 'fileutils'
require_relative '../config_manager.rb'
require_relative '../log/log.rb'
require_relative '../utils/paths.rb'

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
      # TODO hardcoded, extract attributes and read config file from the
      # content repo or overwrite default attributes with a config file
      # NOTE Backends need to be required explicitly with require or
      # require_relative instead of being passed as options[:requires]
      stage_log(:build, 'HTML5 Multipage Backend loaded')
      require File.join(
        File.expand_path(::Toolchain.toolchain_path),
        'adoc-extensions.d/multipage_html5.rb'
      )

      options = {
        attributes: {
          # General
          'root' => ::Toolchain.build_path,
          # Multipage
          'multipage-level' =>
            ::Toolchain::ConfigManager.instance.get('asciidoc.multipage_level'),
          'backend' => 'multipage_html5',
          # CSS
          'linkcss' => true,
          'stylesdir' => 'css',
          'stylesheet' => 'main.css',
          ## Font Awesome
          'icons' => 'font',
          # TOC
          'toc' => 'left',
          # Source Code
          'source-highlighter' => 'coderay',
          'coderay-css' => 'class',
          # Other
          'systemtimestamp' => %x(date +%s),
          'docinfo' => 'shared',
        },
        safe: :safe,
        failure_level: 'WARN'
      }
      Asciidoctor.convert_file(index_path, options)

      # create HTML folder
      html_dir = ::Toolchain.html_path
      Dir.mkdir(html_dir) unless Dir.exist?(html_dir)

      # move web pages to html/
      htmls = Dir[File.join(build_dir, '*.html')].delete_if do |file|
        %w[docinfo toc].any? { |term| File.basename(file).start_with?(term) }
      end
      htmls.each do |html|
        FileUtils.mv(html, html_dir, force: true)
      end

      # move assets to html/
      assets = %w[css js fonts images icons favicon.ico]
      assets.each do |asset|
        from = File.join(build_dir, asset)
        next unless File.file?(from) || Dir.exist?(from)

        stage_log(:build, "... Copying #{asset} from #{from} to #{to}")
        to = File.join(html_dir, asset)
        FileUtils.mv(from, to, force: true)
      end

      stage_log(:build, "Files are in #{html_dir}")
    end
  end
end
