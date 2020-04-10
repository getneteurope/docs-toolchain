# frozen_string_literal: true

require 'test/unit'
require 'json'
require 'nokogiri'
require 'fileutils'
require_relative '../../lib/pre.d/combine_js.rb'
require_relative '../util.rb'
require 'errors'

def assert_file_contains(line, file)
  puts File.read(file)
  assert_block("#{file} does not contain #{line}") do
    IO.foreach(file).any? do |l|
      line.equal?(l.chomp)
    end
  end
end


class TestCombineJS < Test::Unit::TestCase
  JS = ['[1, 2, 3].map(n => n ** 2);', 'var [a,,b] = [1,2,3];']

  def create_files(type)
    files = []
    JS.each_with_index do |script, i|
      file = File.join('js', "js_#{type}_#{i}.js")
      files << file
      write_tempfile(file, script, prefix: '', path: @dir)
    end
    return files
  end

  def fill_html(html, js_files)
    File.open(html, 'w+') do |f|
      js_files.each do |js|
        f.puts(%(<script src="#{js}"></script>))
      end
      # the following need to be ignored
      f.puts(%(<script src="js/vendor/blabla.js"></script>))
      f.puts(%(<script>alert(1);</script>))
      f.puts(%(<script src="js/blablba.js" noblob></script>))
    end
  end

  def setup
    @dir = Dir.mktmpdir
    # header
    @js_header_files = create_files('header')
    @html_header = File.join(@dir, 'docinfo.html')
    fill_html(@html_header, @js_header_files)

    # footer
    @js_footer_files = create_files('footer')
    @html_footer = File.join(@dir, 'docinfo-footer.html')
    fill_html(@html_footer, @js_footer_files)

    @htmls = [@html_header, @html_footer]
    @js_files = [@js_header_files, @js_footer_files]
    ENV['BUILD_PATH'] = @dir
    @combine_object = ::Toolchain::Pre::CombineJS.new(100)
  end

  def teardown
    FileUtils.remove_entry(@dir)
    ENV.delete('BUILD_PATH')
  end

  def test_run_fail
    ENV['BUILD_PATH'] = 'this/clearly/does/not/exist'
    assert_raise(::Toolchain::FileNotFound) do
      @combine_object.run
    end
  end

  def test_run
    # NOTE preliminary checks (adapt if number of lines changes)
    assert_equal(5, IO.readlines(@html_header).size)
    assert_equal(5, IO.readlines(@html_footer).size)

    @combine_object.run

    header_lines = IO.readlines(@html_header, chomp: true)
    footer_lines = IO.readlines(@html_footer, chomp: true)

    assert_equal(4, header_lines.size)
    assert_equal(4, footer_lines.size)

    assert_equal(
      '<script src="js/blob_header.js"></script>',
      header_lines.last)
    assert_equal(
      '<script src="js/blob_footer.js"></script>',
      footer_lines.last)
  end

  def test_get_script_tags
    @htmls.zip(@js_files).each do |html, js|
      doc = Nokogiri::HTML.fragment(File.read(html))
      found = @combine_object.get_script_sources(doc)
      assert_equal(js, found)
    end
  end
end
