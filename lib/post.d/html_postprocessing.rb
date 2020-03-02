# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require_relative '../utils/paths.rb'
require_relative '../utils/adoc.rb'
require_relative '../log/log.rb'
require 'asciidoctor'
require 'nokogiri'

CM = Toolchain::ConfigManager.instance

module Toolchain
  ##
  # Adds modules for postprocessing files.
  module Post
    ##
    # Provides an interface to create a lunr search index
    # from the generated HTML files.
    class TableOfContent < BaseProcess
      def initialize(priority = 0)
        super(priority)
        @html_dir = CM.get('build.html_dir')
        @toc_html_file = CM.get('toc.html_file')
        @html_files_array = Dir.glob('*.html', base: Toolchain.html_path).delete_if do |file|
          File.basename(file).start_with?('docinfo')
        end.map do |file|
          File.join(@html_dir, file)
        end
      end

      ##
      # Injects pre-built HTML table of content into all built HTML files
      # Optionally specifiy which TOC html fragment file +toc_html_file+ to inject in which files +html_files_array+
      #
      # Returns path to created JSON file +json_filepath+, path to creted HTML fragment file +html_path+ and the TOC Has +toc_hash+
      #
      def run(toc_html_file = @toc_html_file, html_files_array = @html_files_array)
        stage_log(:post, '[Inject TOC] Starting')
        html_fragment = File.read(toc_html_file)
        return @html_files_array.map do |html_file|
          inject_fragment_into_html_file(html_fragment, html_file)
        end
      end

      private

      ## Appends HTML fragment +html_fragment+ to top of body of an HTML file +html_file+
      # Returns path of modified HTML file +html_filepath+
      #
      def inject_fragment_into_html_file(html_fragment, html_file)
        file_content = File.read(html_file)
        document = Nokogiri::HTML(file_content)
        document.css('div#toc').remove
        document.css('div#header').children.first.add_previous_sibling(html_fragment)      
        modified_html = document.to_html
        return html_file if File.write(html_file, modified_html)
      end
    end
  end
end

Toolchain::PostProcessManager.instance.register(Toolchain::Post::TableOfContent.new)