# frozen_string_literal: true

require_relative '../lib/pre.d/combine_transpile_js.rb'
require_relative '../lib/pre.d/compile_search_index.rb'
require_relative './util.rb'
require 'zlib'

class TestJsCombineAndTranspile < Test::Unit::TestCase
  ##
  # Creates two samples js files each for a test docinfo.html and test docinfo-footer.html
  # Adds invalid script tags
  # Then combines and transpiles and check results
  #
  def test_combine_and_transpile_js
    # TODO: outsource writing stuff to its own method
    js_header_files_contents = ['[1, 2, 3].map(n => n ** 2);', 'var [a,,b] = [1,2,3];']
    js_header_files_paths = []
    js_header_files_contents.each_with_index do |script, i|
      js_header_files_paths << write_tempfile('js_header_' + i.to_s + '.js', script)
    end
    html_header = "<html><head>\n"
    html_header += '<script src="invalid-file.js"></script>' + "\n"
    js_header_files_paths.each do |path|
      html_header += '<script src="' + path + '"></script>' + "\n"
    end
    html_header += '</head>' + "\n"
    html_header_filepath = write_tempfile('docinfo_head.html', html_header)

    js_footer_files_contents = js_header_files_contents.reverse
    js_footer_files_paths = []
    js_footer_files_contents.each_with_index do |script, i|
      js_footer_files_paths << write_tempfile('js_footer_' + i.to_s + '.js', script)
    end
    html_footer = ''
    js_footer_files_paths.each do |path|
      html_footer += '<script src="' + path + '"></script>' + "\n"
    end
    html_footer += '<script src="invalid-footer-file.js"></script>' + "\n"
    html_footer += '</body></html>'
    html_footer_filepath = write_tempfile('docinfo_footer.html', html_footer)

    docinfo_files_paths = OpenStruct.new('header' => html_header_filepath, 'footer' => html_footer_filepath)
    results = Toolchain::Pre::CombineAndTranspileJS.new.run(docinfo_files_paths)
    assert_equal(2284332409, Zlib.crc32(results[0].js_blob))
    assert_equal(1293230988, Zlib.crc32(results[0].html))
    assert_equal(1211914232, Zlib.crc32(results[1].js_blob))
    assert_equal(2246984566, Zlib.crc32(results[1].html))
  end
end

class TestCompileSearchIndex < Test::Unit::TestCase
  ##
  # Creates lunr index json from an adoc file with include(s)
  #
  def test_compile_search_index
    include_content = 
'[#subsection_one]
== Subsection One
Some more keywords: Credentials, Toolchain, Payment

[#subsubsection_one]
=== Sub Sub Section One
Search for these: Github, Credentials, Toolchain, Payment, Documentation, Credit Card, Rest API, Mooh
It should return the correct anchor(s)
'
include_file_name = File.basename write_tempfile('search_index_include_content.adoc', include_content)
adoc_content = '= Document Title

Put some keywords here
- Credit Card
- Rest API
- Mooh

//-' + "
include::#{include_file_name}[]
"
    adoc = init(adoc_content, "#{self.class.name}_#{__method__}")
    results = Toolchain::Pre::CompileSearchIndex.new.run(adoc)
    assert_equal(2246984566, 2246984566)
  end
end
