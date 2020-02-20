# frozen_string_literal: true

require_relative '../lib/pre.d/combine_transpile_js.rb'
require_relative '../lib/pre.d/create_toc.rb'
require_relative './util.rb'
require 'json'

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
    results = ::Toolchain::Pre::CombineAndTranspileJS.new.run(docinfo_files_paths)
    assert_equal(2_284_332_409, Zlib.crc32(results[0].js_blob))
    assert_equal(1_293_230_988, Zlib.crc32(results[0].html))
    assert_equal(1_211_914_232, Zlib.crc32(results[1].js_blob))
    assert_equal(2_246_984_566, Zlib.crc32(results[1].html))
  end
end

class TestCreateTOC < Test::Unit::TestCase
  ##
  # Tests TOC creation with sample document
  #
  def test_create_toc
    adoc_content = '= Test IDs
[#level_one]
== First 1
This is my first section.

[#level_two]
== Sign 2
Sign here please.

[#level_three]
=== My Section 3

Here is my very own section.
Thank you.

[#level_two_again]
== Another Sign 2
Sign here please.

[#level_three_again]
=== The Omen 3

Here is my very own section.
Thank you.

[#discrete_level_five_outlaw]
[discrete]
===== Outlaw jumps to 5

The outlaw does not get caught because he is discrete

[#level_four]
==== My Section 4

[#level_five]
===== Getting sectioned at 5

Sensing a pattern here?

[#level_six]
====== 66 6

[#level_seven]
======= In too deep 7

    '
    adoc = init(adoc_content, "#{self.class.name}_#{__method__}")
    ::Toolchain::ConfigManager.instance.load
    json_filepath = ::Toolchain::Pre::CreateTOC.new.run(adoc)
    toc_object = JSON.parse(File.read(json_filepath))
    assert_equal(toc_object['children'][1]['children'][0]['children'][0]['children'][0]['title'], 'Getting sectioned at 5')
  end
end
