# frozen_string_literal: true

require_relative '../lib/post.d/compile_search_index.rb'
require_relative '../lib/utils/create_toc.rb'
require_relative './util.rb'
require 'test/unit'
require 'fileutils'

class TestCompileSearchIndex < Test::Unit::TestCase
  ##
  # Creates lunr index json from an adoc file with include(s)
  #
  def test_compile_search_index
    content =
      '<!DOCTYPE html>
<html>
<head><title>Unit test</title></head>
<body>

<div id="content">

<div class="sect2">
<h3 id="ApplePay_Main"><a class="anchor" href="#ApplePay_Main"></a><a class="link" href="#ApplePay_Main">Apple Pay</a></h3>
<div class="paragraph">
<p>Test Apple Pay paragraph is here.</p>
</div>

<div class="sect3">
<h3 id="first-head">My First Heading</h3>
<div class="paragraph">
<p>My first paragraph.</p>
</div>
</div>

</div>

</div>

</body>
</html>'
    outfile = '/tmp/test_index.json'
    dbfile = '/tmp/test_db.json'

    ::Toolchain::ConfigManager.instance.load
    toc_file = ::File.join(::Toolchain.build_path, CM.get('toc.json_file'))
    FileUtils.mkdir_p(::File.dirname(toc_file))
    ::File.write(toc_file, '{}')
    index, lookup = with_tempfile(content, '_CompileSearchIndex') do |file|
      ::Toolchain::Post::CompileSearchIndex.new.run(file, outfile: outfile, dbfile: dbfile)
    end
    assert_equal(%w[title body file], index['fields'])
    assert_true(lookup.size.positive?)
  end
end
