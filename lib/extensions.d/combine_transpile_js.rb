# frozen_string_literal: true

require_relative '../extension_manager.rb'
require_relative '../base_extension.rb'
require 'Nokogiri'

module Toolchain
  ##
  # Adds modules for preprocessing files.
  class CombineAndTranspileJs < BaseExtension
    ##
    # Combines js files referenced in docinfo{,-footer}.html to a single .js file
    # and transpiles them with BabelJS
    # then reinserts the combined and transpiled file as script tags into tbe html files
    # TODO: add files from header.js.d to docinfo.html and footer.js.d to docinfo-footer.html
    def combine_and_transpile_js(docinfo_filepaths = nil)
      content_path = ::Toolchain.content_path
      docinfo_header_path = if docinfo_filepaths.nil?
                              content_path + '/docinfo.html'
                            else
                              docinfo_filepaths.header
                            end

      docinfo_footer_path = if docinfo_filepaths.nil?
                              content_path + '/docinfo.html'
                            else
                              docinfo_filepaths.footer
                            end
      js_files = Dir[content_path + '/js/*.js']
      pp get_script_src_from_html_file(docinfo_header_path)
    end

    ##
    # parses html file and returns array +script_sources+ of all script tags' src attribute
    # e.g. <script src="js/1.js"> --> ['js/1.js']
    def get_script_src_from_html_file(path)
      unless File.file?(path)
        # raise Exception.new("Could not read html file " + path)
      end
      doc = File.open(path) { |f| Nokogiri::HTML(f) }
      script_tags = doc.xpath('//script')
      script_tags.each do |tag|
        log('JS', 'skipping script tag without "src" attribute', :magenta) unless tag.key?('src')
        # TODO: add check if script has src but children. then its a sloppy html code.
        pp tag['src']
      end
      script_tags
    end

    def run(docinfo_filepaths = nil)
      combine_and_transpile_js(docinfo_filepaths)
    end
  end
end
