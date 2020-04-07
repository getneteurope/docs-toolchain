# frozen_string_literal: true

require 'test/unit'
require 'fileutils'
require 'json'
require_relative '../../lib/post.d/compile_search_index.rb'
require_relative '../util.rb'

class TestCompileSearchIndex < Test::Unit::TestCase
  ##
  # Creates lunr index json from an adoc file with include(s)
  #
  def test_compile_search_index
    outfile = File.join(Dir.tmpdir, 'test_index.json')
    dbfile = File.join(Dir.tmpdir, 'test_db.json')

    Toolchain::ConfigManager.instance.load
    toc_file = ::File.join(::Toolchain.build_path,
      Toolchain::ConfigManager.instance.get('toc.json_file'))
    FileUtils.mkdir_p(::File.dirname(toc_file))
    File.write(toc_file, '{}')

    index, lookup = Dir.mktmpdir do |tmpdir|
      htmldir = File.join(tmpdir, 'html')
      Dir.mkdir(htmldir)
      html = File.join(htmldir, 'test.html')
      FileUtils.cp(File.join(__dir__, 'test.html'), html)

      ENV['HTML_DIR'] = htmldir
      result = Toolchain::Post::CompileSearchIndex.new
        .run(outfile: outfile, dbfile: dbfile)
      ENV.delete('HTML_DIR')
      break result
    end
    assert_equal(%w[title body file], index['fields'])
    assert_true(lookup.size.positive?)
  end

  def test_convert_nodes
    toc = JSON.parse(File.read(File.join(__dir__, 'toc.json')))
    nodes = Toolchain::TableOfContent.convert_nodes(toc)
    ref = File.read(File.join(__dir__, 'nodes.ref.json'))
  end
end
