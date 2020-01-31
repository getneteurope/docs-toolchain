
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
    results = Toolchain::CombineAndTranspileJs.new.run(docinfo_files_paths)
    assert_equal(Zlib.crc32(results[0].js_blob), 2284332409)
    assert_equal(Zlib.crc32(results[0].html), 3050793018)
    assert_equal(Zlib.crc32(results[1].js_blob), 1211914232)
    assert_equal(Zlib.crc32(results[1].html), 30269091)
  end
end
