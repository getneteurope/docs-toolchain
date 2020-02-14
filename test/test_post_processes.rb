# frozen_string_literal: true

require_relative '../lib/post.d/compile_search_index.rb'
require_relative './util.rb'
require 'zlib'



class TestCompileSearchIndex < Test::Unit::TestCase
  ##
  # Creates lunr index json from an adoc file with include(s)
  #
  def test_compile_search_index
    content =
      '<!DOCTYPE html>
<html>
<body>

<div id="content">
<div class="sect3">
<h3>My First Heading</h1>
<p>My first paragraph.</p>
</div>
</div>

</body>
</html>'
    outfile = '/tmp/test_index.json'
    index = with_tempfile(content) do |file|
      Toolchain::Post::CompileSearchIndex.new.run(file, outfile: outfile)
    end
    assert_equal(175988315, Zlib.crc32(index.inspect))
  end
end
