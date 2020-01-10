# frozen_string_literal: true

require 'asciidoctor'
require_relative '../../stages/test/ruby/main_module.rb'
require_relative '../../stages/test/ruby/cli.rb'
Dir['../../stages/test/modules.d/*.rb'].each { |file| require file }

def err_assert(errors, text)
  assert_true(errors.any? { |err| err[:msg].start_with?(text) })
end

def init(content, name)
  document, _original = init2(content, name)
  return document
end

def init2(content, name)
  tmp = File.open(File.join('/tmp', "test_toolchain_#{name}.adoc"), 'w+')
  begin
    tmp.write(content)
  ensure
    tmp.close
  end
  document = Asciidoctor.load_file(tmp.path, safe: :safe, catalog_assets: true)
  document.convert
  original = Asciidoctor.load_file(tmp.path, safe: :safe, catalog_assets: true)
  return document, original
end

class TestLinkChecker < Test::Unit::TestCase
  def test_links
    omit_if(ENV.key?('SKIP_NETWORK'), 'Tests with networking disabled')
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
  def test_short_ids
    wrong_ref = %w[illegal_$ign my_se¢tion]
    adoc = '= Test IDs
[#first]
== First
This is my first section.

[#illegal_$ign]
== Sign
Sign here please.

[#my_se¢tion]
=== My Section

Here is my very own section.
Thank you.
    '
    document, original = init2(adoc, "#{self.class.name}_#{__method__}")
    errors = Toolchain::IdChecker.new.run(document, original)
    omit_if(errors.length.zero?, 'Skip: errors empty, fix this issue first')
    assert_equal(2, errors.length)
    wrong_ids = parse(errors)
    assert_equal(wrong_ref, wrong_ids)
  end

  def test_long_ids
    wrong_ref = %w[illegal_$ign my_se¢tion]
    adoc = '= Test IDs
[[first]]
== First
This is my first section.

[[illegal_$ign]]
== Sign
Sign here please.

[[my_se¢tion]]
=== My Section

Here is my very own section.
Thank you.
    '
    document, original = init2(adoc, "#{self.class.name}_#{__method__}")
    errors = Toolchain::IdChecker.new.run(document, original)
    omit_if(errors.length.zero?, 'Skip: errors empty, fix this issue first')
    assert_equal(2, errors.length)
    wrong_ids = parse(errors)
    assert_equal(wrong_ref, wrong_ids)
  end

  private

  def parse(errors)
    return errors.map do |err|
      msg = err[:msg]
      startc = msg.index("'") + 1
      endc = msg.index("'", startc) - 1
      msg[startc..endc]
    end
  end
end
