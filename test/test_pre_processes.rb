# frozen_string_literal: true

require_relative '../lib/pre.d/combine_transpile_js.rb'
require_relative '../lib/pre.d/create_toc.rb'
require_relative './util.rb'
require 'json'
require 'test/unit'

class TestJsCombineAndTranspile < Test::Unit::TestCase
  CONTENT = ['[1, 2, 3].map(n => n ** 2);', 'var [a,,b] = [1,2,3];']
  ##
  # Creates two samples js files each for a test docinfo.html and test docinfo-footer.html
  # Adds invalid script tags
  # Then combines and transpiles and check results
  #
  def test_combine_and_transpile_js
    # TODO: outsource writing stuff to its own method
    # HEADER
    js_header_files_paths = []
    CONTENT.each_with_index do |script, i|
      js_header_files_paths << write_tempfile('js_header_' + i.to_s + '.js', script).delete_prefix('/tmp/')
    end
    html_header = '<script src="invalid-file.js"></script>' + "\n"
    js_header_files_paths.each do |path|
      html_header += '<script src="' + path + '"></script>' + "\n"
    end
    html_header_filepath = write_tempfile('docinfo_header.html', html_header)

    # FOOTER
    js_footer_files_contents = CONTENT.reverse
    js_footer_files_paths = []
    js_footer_files_contents.each_with_index do |script, i|
      js_footer_files_paths << write_tempfile('js_footer_' + i.to_s + '.js', script).delete_prefix('/tmp/')
    end
    html_footer = ''
    js_footer_files_paths.each do |path|
      html_footer += '<script src="' + path + '"></script>' + "\n"
    end
    html_footer += '<script src="invalid-footer-file.js"></script>' + "\n"
    html_footer_filepath = write_tempfile('docinfo_footer.html', html_footer)

    # TESTS
    docinfo_files_paths = OpenStruct.new(
      'header' => html_header_filepath, 'footer' => html_footer_filepath
    )
    results = ::Toolchain::Pre::CombineAndTranspileJS.new.run(docinfo_files_paths)
    assert_equal(CONTENT.join("\n\n") + "\n",
      File.read(results[0].js_blob_path))
    assert_equal('<script src="js/blob_header.js"></script>',
      results[0].html.chomp)
    assert_equal(CONTENT.reverse.join("\n\n") + "\n",
      File.read(results[1].js_blob_path))
    assert_equal('<script src="js/blob_footer.js"></script>',
      results[1].html.chomp)
  end
end

# class TestCreateTOC < Test::Unit::TestCase
#   require 'nokogiri'
#   ##
#   # Tests TOC creation with sample document
#   #
#   def test_create_toc
#     adoc_content = '= Test IDs
# [#level_one]
# == First 1
# This is my first section.

# [#level_two]
# == Sign 2
# Sign here please.

# [#level_three]
# === My Section 3

# Here is my very own section.
# Thank you.

# [#level_two_again]
# == Another Sign 2
# Sign here please.

# [#level_three_again]
# === The Omen 3

# Here is my very own section.
# Thank you.

# [[discrete_level_five_outlaw]]
# [discrete]
# ===== Outlaw jumps to 5

# The outlaw does not get caught because he is discrete

# [[level_four]]
# ==== My Section 4

# [#level_five]
# ===== Getting sectioned at 5

# Sensing a pattern here?

# [[level_six]]
# ====== 66 6

# [#level_seven]
# ======= In too deep 7

# [#level_nowhere]
# [discrete]
# === Hide me senpai

#     '
#     adoc = init(adoc_content, "#{self.class.name}_#{__method__}")
#     ::Toolchain::ConfigManager.instance.load
#     json_filepath, html_filepath, toc_hash = ::Toolchain::Pre::CreateTOC.new.run(adoc)

#     # Test JSON file
#     toc_object = JSON.parse(File.read(json_filepath))
#     assert_equal(toc_object['children'][1]['children'][0]['children'][0]['children'][0]['title'], 'Getting sectioned at 5')

#     # Test HTML file
#     toc_html = Nokogiri::HTML.fragment(File.read(html_filepath))
#     assert_equal(toc_html.css('#toc > ul > li#toc_level_two > a + ul > li > a').attribute('href').value, 'level_three.html#level_three')
#   end
# end
