# frozen_string_literal: true

require 'asciidoctor'
require_relative '../../stages/test/ruby/main_module.rb'
require_relative '../../stages/test/ruby/cli.rb'
Dir['../../stages/test/modules.d/*.rb'].each { |file| require file }

def err_assert(errors, text)
  assert_true(errors.any? { |err| err[:msg].start_with?(text) })
end

class TestLinkChecker < Test::Unit::TestCase
  def test_help_cli
    adoc = '= Test links

1. https://github.com/wirecard/docs-toolchain[Docs Toolchain]
2. https://github.com/asciidoctor/asciidoctor-exteansions-lab[Asciidoctor Extensions Lab]
3. https://adfasdgea.asd/adfadfasdf/[Unknown Domain]
4. http://111.222.123.48[Random IP]
'
    document = Asciidoctor.load(adoc, catalog_assets: true)
    document.convert
    assert_equal(4, document.references[:links].length)
    errors = Toolchain::LinkChecker.new.run(document)
    assert_equal(3, errors.length)
    err_assert(errors, '[404] Not Found') # 2.
    err_assert(errors, 'SocketError') # 3.
    err_assert(errors, 'Net::OpenTimeout') # 4.
  end
end
