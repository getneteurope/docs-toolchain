# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require 'nokogiri'
require 'babel/transpiler'

module Toolchain
  module Pre
    ##
    # Adds modules for preprocessing files.
    class CombineAndTranspileJS < BaseProcess
      SCRIPT_TAG_REGEX = %r{<script\ .*\ *src=['"](?<source>[a-zA-Z0-9_\.\-/]+)['"]>}.freeze

      def initialize(priority = 0)
        super(priority)
        @header_name_default = 'docinfo-header.html'
        @footer_name_default = 'docinfo-footer.html'
      end

      ##
      # Combines JS files referenced in docinfo{,-footer}.html
      # into a single .js file, transpiles them with BabelJS and
      # then reinserts the combined and transpiled file as
      # script tags into the HTML files.
      #
      # Returns the results of the substitution.
      def run(filepaths = nil)
        # TODO: add files from header.js.d to docinfo.html and footer.js.d to docinfo-footer.html
        content_path = File.join(::Toolchain.content_path, 'content')
        header_path = filepaths.nil? ? File.join(content_path, @header_name_default) : filepaths.header
        footer_path = filepaths.nil? ? File.join(content_path, @footer_name_default) : filepaths.footer
        # js_header_files = Dir[content_path + '/js/header.js.d/*.js']
        results = []
        Dir.chdir File.dirname(header_path) do
          [header_path, footer_path].each do |docpath|
            stage_log('pre', "[JS Combine and Transpile] -> #{docpath}")
            begin
              results << combine_and_replace_js(docpath)
            rescue StandardError => e
              log('ERROR', 'JS Combine and Transpile', :red)
              log('ERROR', e.message, :red)
              log('ERROR', "docpath: #{docpath}", :red)
              raise e
            end
          end
        end
        return results
      end

      ##
      # Combines JS files found in html file
      # Returns string of combined js files
      #
      def combine_js(path, seperator = "\n\n")
        get_script_src_from_html_file(path).map do |s|
          File.read(s)
        end.join(seperator)
      end

      ##
      # Remove all <script src="..."/> tags and replace with single <script src="blob"/>
      # Takes +path+ and string +js_blob+ as input
      #
      # Returns html string +html_string+
      #
      def replace_js_tags_with_blob(path, js_blob)
        # TODO: solve this with nokogiri fragment parser (which either
        # removes needed or adds unnecessary tags..)
        #
        # derive .js path from html filename
        # e.g. docinfo-footer.html => content/js/docinfo-footer.js
        js_blob_path = File.join(
          ::Toolchain.content_path, 'js', File.basename(path, '.*') + '_blob.js'
        )
        js_blob_path_relative = js_blob_path
          .delete_prefix(::Toolchain.content_path + '/')
          .delete_prefix('content/')
        js_dir = File.dirname(js_blob_path)
        FileUtils.mkdir_p(js_dir) unless File.directory?(js_dir)
        File.open(js_blob_path, 'w+') { |file| file.puts(js_blob) }

        html_content_lines = File.read(path).lines

        # get lines where there are script tags with src attribute
        script_tags_idx = []
        html_content_lines.each_with_index do |l, i|
          script_tags_idx << i if l.match?(SCRIPT_TAG_REGEX)
        end

        # replace last script tag with blob script tag
        blob_script_tag = "<script src=\"#{js_blob_path_relative}\"></script>\n"
        html_content_lines[script_tags_idx.pop] = blob_script_tag unless script_tags_idx.empty?

        # remove all other script tags that use src attribute
        script_tags_idx.each { |i| html_content_lines[i] = nil }.reject(&:nil?)

        html_string = html_content_lines.join
        return html_string
      end

      ##
      # Replaces all js tags in an html file +path+ with a tag that includes one big blob js.
      #
      # Returns an OpenStruct +{ path, js_blob, html }+.
      #
      def combine_and_replace_js(path)
        js_blob = combine_js(path)
        js_blob = Babel::Transpiler.transform(js_blob)['code']
        # TODO: minify js blob. may be unnecessary using transport stream compression anyway
        html_string = replace_js_tags_with_blob(path, js_blob)
        File.open(path, 'w+') do |file|
          log('JS', 'insert js tag for blob into ' + path, :yellow)
          file.puts(html_string)
        end
        return OpenStruct.new(
          path: path,
          js_blob: js_blob,
          html: html_string
        )
      end

      ##
      # Parses html file +path+ loking for javascript files
      #
      # Returns +script_source_files+ array containing "src" attribute values of script
      #   e.g. <script src="js/1.js"> --> ['js/1.js']
      def get_script_src_from_html_file(path)
        unless File.file?(path)
          # raise Exception.new("Could not read html file " + path)
        end
        doc = File.open(path) { |f| Nokogiri::HTML(f) }
        file = File.basename(path)
        # change dir to content/ so we can find js/*.js
        script_source_files = doc.xpath('//script').map do |s|
          line_nr = s.line.to_s
          unless s.key?('src')
            log('JS', "[#{file}:#{line_nr}] skipping script tag without \"src\" attribute.", :yellow)
            next
          end
          unless File.exist?(s.attribute('src'))
            log('JS', "[#{file}:#{line_nr}] skipping tag, src not found: #{s.attribute('src')}", :yellow)
            next
          end
          unless s.children.empty?
            log('JS', "[#{file}:#{line_nr}] skipping invalid script tag.", :yellow)
            next
          end
          s.attribute('src')
        end
        script_source_files = script_source_files.compact # remove nil
        return script_source_files
      end
    end
  end
end

Toolchain::PreProcessManager.instance.register(Toolchain::Pre::CombineAndTranspileJS.new)
