# frozen_string_literal: true

require_relative '../extension_manager.rb'
require_relative '../base_extension.rb'
require 'Nokogiri'

module Toolchain
  ##
  # Adds modules for preprocessing files.
  class CombineAndTranspileJs < BaseExtension
    @docinfo_header_name_default = 'docinfo.html'
    @docinfo_footer_name_default = 'docinfo-footer.html'
    ##
    # Combines js files referenced in docinfo{,-footer}.html to a single .js file
    # and transpiles them with BabelJS
    # then reinserts the combined and transpiled file as script tags into tbe html files
    # TODO: add files from header.js.d to docinfo.html and footer.js.d to docinfo-footer.html
    def combine_and_transpile_js(docinfo_filepaths = nil)
      content_path = ::Toolchain.content_path
      docinfo_header_path = if docinfo_filepaths.nil?
                              content_path + '/' + @docinfo_header_name_default
                            else
                              docinfo_filepaths.header
                            end

      docinfo_footer_path = if docinfo_filepaths.nil?
                              content_path + '/' + @docinfo_footer_name_default
                            else
                              docinfo_filepaths.footer
                            end
      #js_header_files = Dir[content_path + '/js/header.js.d/*.js']
      [docinfo_header_path, docinfo_footer_path].each do |docpath|
        replace_js_files_with_blob(docpath)
      end
    end

    ##
    # Replaces all js tags in an html file +path+ with a tag that includes one big blob js.
    # Writes to file and returns +path+ or nil if an error occured.
    def replace_js_files_with_blob(path)
      sources = get_script_src_from_html_file(path)
      js_blob = sources.map do |s|
        File.read(s)
      end.join("\n\n")
      puts js_blob
      # check if head tag exits ===> isHeader
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
      script_source_files = doc.xpath('//script').map do |s|
        line_nr = s.line.to_s
        unless s.key?('src')
          log('JS', "#{file}:#{line_nr}" + ' skipping script tag without "src" attribute.', :yellow)
          next
        end
        unless File.exist?(s.attribute('src'))
          log('JS', "#{file}:#{line_nr}" + ' skipping tag, src not found: ' + s.attribute('src'), :yellow)
          next
        end
        unless s.children.empty?
          log('JS', "#{file}:#{line_nr}" + ' skipping invalid script tag.', :yellow)
          next
        end
        s.attribute('src')
      end
      script_source_files = script_source_files.compact # remove nil
      return script_source_files
    end

    def run(docinfo_filepaths = nil)
      combine_and_transpile_js(docinfo_filepaths)
    end
  end
end
