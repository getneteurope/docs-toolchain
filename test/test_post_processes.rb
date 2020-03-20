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
<p>
 Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Integer massa odio, bibendum ut vulputate sit amet, fringilla in massa.
Donec vitae venenatis dolor. Suspendisse efficitur cursus arcu.
Duis tincidunt et quam et dapibus. Vivamus ut dui vitae nisl dignissim faucibus.
Mauris venenatis eleifend nisi ut vehicula. Suspendisse semper viverra consequat.
Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.

Donec maximus vestibulum urna id ullamcorper.
Sed sem tortor, maximus a arcu id, accumsan varius ante.
Pellentesque accumsan rhoncus est non sagittis.
Sed ac eros sit amet neque semper ullamcorper vel eget mi.
Sed non luctus nunc. Nulla non massa ac libero iaculis bibendum.
Nulla non porttitor risus. Fusce ac molestie elit.
Fusce purus est, accumsan eu odio vel, ornare tristique odio.
Suspendisse ullamcorper mauris ac iaculis pellentesque.
Donec rhoncus tortor vel est ultrices dignissim.
Fusce tincidunt gravida orci eget placerat. Etiam nec scelerisque diam.
Praesent quis feugiat enim.
</p>
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
