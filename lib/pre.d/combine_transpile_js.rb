# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require 'nokogiri'
require 'babel/transpiler'
# toolchain
require 'errors'

module Toolchain
  module Pre
    ##
    # Adds modules for preprocessing files.
    class CombineAndTranspileJS < BaseProcess
      SCRIPT_TAG_REGEX = %r{<script\ .*\ *src=['"](?<source>[a-zA-Z0-9_\.\-/]+)['"]>}.freeze

      def initialize(priority = 0)
        super(priority)
        @header_default = 'docinfo.html'
        @footer_default = 'docinfo-footer.html'
      end

      ##
      # Combines JS files referenced in docinfo{,-footer}.html
      # into a single .js file, transpiles them with BabelJS and
      # then reinserts the combined and transpiled file as
      # script tags into the HTML files.
      #
      # Returns the results of the substitution.
      def run(filepaths = nil)
        root = ::Toolchain.build_path
        header_path =
          filepaths.nil? ? File.join(root, @header_default) : filepaths.header
        footer_path =
          filepaths.nil? ? File.join(root, @footer_default) : filepaths.footer
        # js_header_files = Dir[content_path + '/js/header.js.d/*.js']
        results = []
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
        return results
      end

      ##
      # Combines JS files found in html file
      # Returns string of combined js files
      #
      def combine_js(html_path, seperator = "\n\n")
        get_script_src_from_html_file(html_path).map do |js|
          File.read(js)
        end.join(seperator)
      end

      ##
      # Remove all <script src="..."/> tags and replace with single <script src="blob"/>
      # Takes HTML +path+ and string +js_blob+ as input
      #
      # Returns HTML string and JS blob path.
      #
      def replace_js_tags_with_blob(path, js_blob)
        # derive .js path from html filename
        # e.g. docinfo-footer.html => content/js/docinfo-footer.js
        root = ::Toolchain.build_path
        blob_name = path.include?('footer') ? 'footer' : 'header'
        js_blob_path = File.join(
          root, 'js', "blob_#{blob_name}.js"
        )
        js_blob_relpath = js_blob_path.delete_prefix("#{root}/")
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
        blob_script_tag = %(<script src=\"#{js_blob_relpath}\"></script>\n)
        unless script_tags_idx.empty?
          html_content_lines[script_tags_idx.pop] = blob_script_tag
        end

        # remove all other script tags that use src attribute
        script_tags_idx.each { |i| html_content_lines[i] = nil }.reject(&:nil?)

        html_string = html_content_lines.join
        return html_string, js_blob_path
      end

      ##
      # Replaces all js tags in an HTML file +html_path+ with a tag that
      # includes one big blob JS.
      #
      # Returns an OpenStruct +{ html_path, html, js_blob_str, js_blob_path }+.
      #
      def combine_and_replace_js(html_path)
        js_blob_str = combine_js(html_path)
        unless ENV.key?('NO_BABEL')
          js_blob_str = Babel::Transpiler.transform(js_blob_str)['code']
        end
        # TODO: minify js blob.
        # May be unnecessary using transport stream compression anyway
        html_string, js_blob_path = replace_js_tags_with_blob(
          html_path, js_blob_str)

        unless js_blob_str.empty?
          File.open(html_path, 'w+') do |file|
            file.puts(html_string)
          end
        end

        return OpenStruct.new(
          html_path: html_path,
          html: html_string,
          js_blob_str: js_blob_str,
          js_blob_path: js_blob_path
        )
      end

      ##
      # Parses html file +path+ loking for javascript files
      #
      # Returns +script_source_files+ array containing "src" attribute
      # values of script
      #
      #   e.g. <script src="js/1.js"> --> ['js/1.js']
      def get_script_src_from_html_file(html_path)
        unless File.file?(html_path)
          raise(::Toolchain::FileNotFound,
            "Could not read html file #{html_path}")
        end
        doc = File.open(html_path) { |f| Nokogiri::HTML(f) }
        dir = File.dirname(html_path)
        html_file = File.basename(html_path)
        # change dir to content/ so we can find js/*.js
        script_source_files = doc.search('script').map do |stag|
          next if stag.key?('noblob')
          line_nr = stag.line
          next unless stag.key?('src')
          next unless File.exist?(File.join(dir, stag.attribute('src')))
          next unless stag.children.empty?

          ::File.join(dir, stag.attribute('src'))
        end
        script_source_files = script_source_files.compact # remove nil
        return script_source_files
      end
    end
  end
end

# unless ENV.key?('FAST') || ENV.key?('SKIP_COMBINE')
#   Toolchain::PreProcessManager.instance.register(
#     Toolchain::Pre::CombineAndTranspileJS.new)
# end
