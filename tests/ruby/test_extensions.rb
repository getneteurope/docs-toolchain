# frozen_string_literal: true

require 'asciidoctor'
require 'tmpdir'
require_relative '../../stages/test/ruby/main_module.rb'
require_relative '../../stages/test/ruby/cli.rb'
Dir['../../stages/test/modules.d/*.rb'].each { |file| require file }

def err_assert(errors, text)
  assert_true(errors.any? { |err| err[:msg].start_with?(text) })
end

def init(content, name, raw = false)
  document, original = init2(content)
  return document, original if raw

  return document
end

def init2(content, name)
  tmp = File.new(File.join(Dir.tmpdir, "test_toolchain_#{name}.adoc"), 'w+')
  begin
    tmp.write(content)
  ensure
    tmp.close
  end
  document = Asciidoctor.load(tmp.path, safe: :safe, catalog_assets: true)
  document.convert
  original = Asciidoctor.load(tmp.path, safe: :safe, catalog_assets: true)
  return document, original
end

class TestLinkChecker < Test::Unit::TestCase
  def test_links
    omit_if(ENV.key?('SKIP_NETWORK'))
    adoc = '= Test links

1. https://github.com/wirecard/docs-toolchain[Docs Toolchain]
2. https://github.com/asciidoctor/asciidoctor-exteansions-lab[Asciidoctor Extensions Lab]
3. https://adfasdgea.asd/adfadfasdf/[Unknown Domain]
4. http://111.222.123.48[Random IP]
    '
    document = init(adoc, self.class.name)
    assert_equal(4, document.references[:links].length)
    errors = Toolchain::LinkChecker.new.run(document)
    assert_equal(3, errors.length)
    err_assert(errors, '[404] Not Found') # 2.
    err_assert(errors, 'SocketError') # 3.
    err_assert(errors, 'Net::OpenTimeout') # 4.
  end
end

class TestIDChecker < Test::Unit::TestCase
  def test_ids
    wrong_ref = %w[illegal_$ign my_se¢tion]
    adoc = '= Test IDs
[[first]]
== First

[#second]
== Second

[[illegal_$ign]]
== Sign

[#my_se¢tion]
== CC
    '
    document, original = init2(adoc, self.class.name)
    errors = Toolchain::IdChecker.new.run(document, original)
    # assert_equal(2, errors.length)
    wrong_ids = errors.map do |err|
      msg = err[:msg]
      startc = msg.index("'") + 1
      endc = msg.index("'", startc) - 1
      msg[startc..endc]
    end
    assert_equal(wrong_ref, wrong_ids)
  end
end
