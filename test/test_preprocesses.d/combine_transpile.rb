# frozen_string_literal: true

require 'test/unit'
require 'json'
require_relative '../../lib/pre.d/combine_transpile_js.rb'
require_relative '../util.rb'

class TestJsCombineAndTranspile < Test::Unit::TestCase
  CONTENT = ['[1, 2, 3].map(n => n ** 2);', 'var [a,,b] = [1,2,3];']

  def setup
    js_header_files_paths = []
    CONTENT.each_with_index do |script, i|
      js_header_files_paths << write_tempfile("js/js_header_#{i}.js", script).delete_prefix('/tmp/')
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
      js_footer_files_paths << write_tempfile("js_footer_#{i}.js", script).delete_prefix('/tmp/')
    end
    html_footer = ''
    js_footer_files_paths.each do |path|
      html_footer += '<script src="' + path + '"></script>' + "\n"
    end
    html_footer += '<script src="invalid-footer-file.js"></script>' + "\n"
    html_footer_filepath = write_tempfile('docinfo_footer.html', html_footer)

    # TESTS
    # TODO: add test for noblob js tags
    @docinfo_files_paths = OpenStruct.new(
      'header' => html_header_filepath, 'footer' => html_footer_filepath
    )
    ENV['BUILD_PATH'] = '/tmp'
  end

  def teardown
    ENV.delete('BUILD_PATH')
  end

  ##
  # Creates two samples js files each for a test docinfo.html and test docinfo-footer.html
  # Adds invalid script tags
  # Then combines and transpiles and check results
  #
  def test_no_babel
    # babel disabled
    ENV['NO_BABEL'] = 'true'
    results = ::Toolchain::Pre::CombineAndTranspileJS.new.run(@docinfo_files_paths)
    ENV.delete('NO_BABEL')
    assert_equal(CONTENT.join("\n\n") + "\n",
      File.read(results[0].js_blob_path))
    assert_equal('<script src="js/blob_header.js"></script>',
      results[0].html.chomp)
    assert_equal(CONTENT.reverse.join("\n\n") + "\n",
      File.read(results[1].js_blob_path))
    assert_equal('<script src="js/blob_footer.js"></script>',
      results[1].html.chomp)
  end

  def test_babel
    # babel enabled
    results = ::Toolchain::Pre::CombineAndTranspileJS.new.run(@docinfo_files_paths)
    result0 = File.read(results[0].js_blob_path)
    assert_equal('"use strict";', result0.split(/\r?\n/).first, 'Prepends "use strict"')
    assert_match('[1, 2, 3].map(function (n) {', result0, 'Converts arrow lambda function')
    assert_match('return Math.pow(n, 2);', result0, 'Converts infix power (x ** 2) to Math.pow')
  end
end
