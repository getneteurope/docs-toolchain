# frozen_string_literal: true

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
      docinfo_path = docinfo_filepaths.nil ? content_path + '/docinfo.html' ; docinfo_filepaths.header
      docinfo_footer_path = docinfo_filepaths.nil ? content_path + '/docinfo.html' ; docinfo_filepaths.footer

      js_files = Dir[content_path + '/js/*.js']
      pp js_files
    end

    def run(docinfo_filepaths = nil)
        combine_and_transpile_js(docinfo_filepaths)
    end
  end
end
