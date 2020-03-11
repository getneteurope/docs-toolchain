# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require_relative '../utils/paths.rb'
require_relative '../utils/adoc.rb'
require_relative '../log/log.rb'
require 'asciidoctor'
require 'nokogiri'

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
        @toc_html_file = File.join(
          ::Toolchain.build_path,
          CM.get('toc.html_file')
        )
        @html_files_array = Dir.glob('*.html', base: ::Toolchain.html_path).map do |file|
          File.join(::Toolchain.html_path, file)
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
        page_id = File.basename(html_file, '.html') # TODO find better way to get page_id
        toc_document = Nokogiri::HTML.fragment(html_fragment)
        stage_log(:post, '[Inject TOC] Starting')
        toc_document = tick_toc_checkboxes(page_id, toc_document)
        document.css('div#toc').remove
        document.css('div#header').children.first.add_previous_sibling(toc_document.to_html)
        modified_html = document.to_html
        return html_file if File.write(html_file, modified_html)
      end
    end
  end
end

# Toolchain::PostProcessManager.instance.register(Toolchain::Post::TableOfContent.new)
