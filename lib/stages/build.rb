# frozen_string_literal: true

require 'asciidoctor'
require 'fileutils'
require_relative '../utils.rb'

def mkdir(path)
  Dir.mkdir(path) unless Dir.exist?(path)
end

module Toolchain
  module Build
    DEFAULT_BUILD_DIR = '/tmp/build'

    def self.setup(build_dir = DEFAULT_BUILD_DIR, content: 'content')
      raise "Directory '#{content}' does not exist" unless Dir.exist?(content.to_s)

      mkdir(build_dir)
      status = system("cp -r #{content}/* #{build_dir}")
      raise "Could not cp #{content}/* to #{build_dir}" unless status
    end

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
      files_to_copy.each do |f|
        f = File.join(build_dir, f)
        FileUtils.mv(f, html_dir, force: true) if File.exist?(f)
      end
      stage_log(:build, "Files are in #{html_dir}")
    end
  end
end
