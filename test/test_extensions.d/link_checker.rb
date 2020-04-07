# frozen_string_literal: true

require 'test/unit'
require_relative '../../lib/extensions.d/link_checker.rb'
require_relative '../util.rb'

class TestLinkChecker < Test::Unit::TestCase
  def test_links
    omit_if(ENV.key?('SKIP_NETWORK'), 'Tests with networking disabled')
    adoc_content = '= Test links

1. https://github.com/wirecard/docs-toolchain[Docs Toolchain]
2. https://github.com/asciidoctor/asciidoctor-exteansions-lab[Asciidoctor Extensions Lab]
3. https://adfasdgea.asd/adfadfasdf/[Unknown Domain]
4. http://111.222.123.48[Random IP]
    '
    adoc = init(adoc_content, "#{self.class.name}_#{__method__}")
    assert_equal(4, adoc.parsed.references[:links].length)
    errors = Toolchain::LinkChecker.new.run(adoc)
    assert_equal(3, errors.length)
    assert_any_startwith(errors, '[404] Not Found') # 2.
    assert_any_startwith(errors, 'SocketError') # 3.
    assert_any_startwith(errors, 'Net::OpenTimeout') # 4.
  end

  def test_format_net_exception
    msg = Toolchain.format_net_exception(StandardError.new('Test'), nil)
    assert_match(/Unknown Exception/, msg)
  end
end

