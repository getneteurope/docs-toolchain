# frozen_string_literal: true

# Test directly:
# SKIP_NETWORK=true ruby tests/ruby/test_extensions.rb

require 'asciidoctor'
require 'test/unit'
require_relative '../lib/stages/test.rb'
require_relative './util.rb'
extensions_dir = File.join(__dir__, '..', 'lib', 'extensions.d', '*.rb')
Dir[extensions_dir].each { |file| require file }

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
    document, original, attributes = init(adoc, "#{self.class.name}_#{__method__}")
    errors = Toolchain::IdChecker.new.run(document, original, attributes)
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
    document, original, attributes = init(adoc, "#{self.class.name}_#{__method__}")
    errors = Toolchain::IdChecker.new.run(document, original, attributes)
    assert_equal(2, errors.length)
    wrong_ids = parse(errors)
    assert_equal(wrong_ref, wrong_ids)
  end

  def test_attributes_in_anchors
    inc1_adoc = ':chapter: bad_chapter _anchor
:chapter_anchor: good
=== Boo
soome text
    '

    inc2_adoc = '=== chapter 2
one more chapter with invalid ANCHOR
[#{chapter}]
[#{chapter_anchor}]
== heading in chapter 2
    '

    attr_in_anchors_inc1_file_name = File.basename write_tempfile('attributes_in_anchors_inc1.adoc', inc1_adoc)
    attr_in_anchors_inc2_file_name = File.basename write_tempfile('attributes_in_anchors_inc2.adoc', inc2_adoc)

    adoc = ":env-payment-processor:
index text
include::#{attr_in_anchors_inc1_file_name}[]
filler
include::#{attr_in_anchors_inc2_file_name}[]

//- comment
    "
    attr_in_anchors_file_path = write_tempfile('attributes_in_anchors.adoc', adoc)

    document, original, attributes = init(adoc, "#{self.class.name}_#{__method__}")



exit


    errors = Toolchain::IdChecker.new.run(document, original, attributes)

    log('ATTRIBUTES_HERE_2', attributes)

    assert_equal(0, errors.length)
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
    assert_any_startwith(errors, '[404] Not Found') # 2.
    assert_any_startwith(errors, 'SocketError') # 3.
    assert_any_startwith(errors, 'Net::OpenTimeout') # 4.
  end
end

class TestPatternBlacklist < Test::Unit::TestCase
  def test_pattern_blacklist
    adoc = '= Bad lines

======= too long heading
WPP
document-center

    '
    blacklist_patterns = '
# do not match this comment
// do not match this comment
/document-center/
/WPP/
document
/={6,}/
/bad_word/
    '
    blacklist_file_path = write_tempfile('blacklist_patterns.txt', blacklist_patterns)
    document, original = init(adoc, "#{self.class.name}_#{__method__}", 'test_toolchain_pattern_blacklist.adoc')
    errors = Toolchain::PatternBlacklist.new.run(document, original, blacklist_file_path)
    assert_equal(3, errors.length)
  end
end
