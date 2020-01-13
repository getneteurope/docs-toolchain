# frozen_string_literal: true

require 'asciidoctor'
require 'test/unit'
require_relative '../../stages/test/ruby/main_module.rb'
require_relative '../../stages/test/ruby/cli.rb'
Dir['../../stages/test/modules.d/*.rb'].each { |file| require file }

def assert_any_startwith(errors, text)
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

class TestPatternBlacklist < Test::Unit::TestCase
  def test_pattern_blacklist
    adoc = '= Bad lines

======= too long heading

document-center

    '
    document, original = init2(adoc, "#{self.class.name}_#{__method__}")
    errors = Toolchain::PatternBlacklist.new.run(document, original)
    assert_equal(2, errors.length)
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
