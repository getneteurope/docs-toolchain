# frozen_string_literal: true

require 'asciidoctor'
require_relative '../../stages/test/ruby/main_module.rb'
require_relative '../../stages/test/ruby/cli.rb'
Dir['../../stages/test/modules.d/*.rb'].each { |file| require file }

class TestLinkChecker < Test::Unit::TestCase
  def setup
    $stdout.sync = true
  end

  def teardown
    $stdout.sync = STDOUT.sync
  end

  def test_help_cli
    adoc = '= Test links

1. https://github.com/wirecard/docs-toolchain[Docs Toolchain]
2. https://github.com/asciidoctor/asciidoctor-exteansions-lab[Asciidoctor Extensions Lab]
3. https://adfasdgea.asd/adfadfasdf/[Unknown Domain]
4. http://111.222.123.48[Random IP]
'
    document = Asciidoctor.load(adoc)
    document.convert
    output = with_captured_stdout do
      Toolchain::LinkChecker.new.run(document)
    end
    STDOUT.puts output
    STDOUT.flush
    assert_match(/[404] Not Found/, output) # 2.
    assert_match(/SocketError/, output) # 3.
    assert_match(/Net::OpenTimeout/, output) # 4.
  end
end
