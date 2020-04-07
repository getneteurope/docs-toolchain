# frozen_string_literal: true

require 'test/unit'
require_relative '../../lib/extensions.d/id_checker.rb'
require_relative '../util.rb'

class TestIDChecker < Test::Unit::TestCase
  def test_short_ids
    wrong_ref = %w[illegal_$ign my_se¢tion]
    adoc_content = '= Test IDs
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
    adoc = init(adoc_content, "#{self.class.name}_#{__method__}")
    errors = Toolchain::IdChecker.new.run(adoc)
    assert_equal(2, errors.length)
    wrong_ids = parse(errors)
    assert_equal(wrong_ref, wrong_ids)
  end

  def test_long_ids
    wrong_ref = %w[illegal_$ign my_se¢tion]
    adoc_content = '= Test IDs
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
    adoc = init(adoc_content, "#{self.class.name}_#{__method__}")
    errors = Toolchain::IdChecker.new.run(adoc)
    assert_equal(2, errors.length)
    wrong_ids = parse(errors)
    assert_equal(wrong_ref, wrong_ids)
  end

  def test_attributes_in_anchors
    inc1_adoc = ':bad_anchor: bad_chapter _anchor
:good_anchor: this_is_good
=== Boo
soome text
    '

    inc2_adoc = '=== chapter 2
one more chapter with invalid ANCHOR
hui
[#{good_anchor}]
== some
text
[[hardcoded]]
[#{bad_anchor}]
== heading in chapter 2
    '
    attr_in_anchors_inc1_file_name = File.basename write_tempfile('attributes_in_anchors_inc1.adoc', inc1_adoc)
    attr_in_anchors_inc2_file_name = File.basename write_tempfile('attributes_in_anchors_inc2.adoc', inc2_adoc)

    adoc_content = ":env-payment-processor:
index text
include::#{attr_in_anchors_inc1_file_name}[]
filler
include::#{attr_in_anchors_inc2_file_name}[]

//- comment
    "
    #attr_in_anchors_filepath = write_tempfile('attributes_in_anchors.adoc', adoc_content)
    adoc = init(adoc_content, "#{self.class.name}_#{__method__}")
    errors = Toolchain::IdChecker.new.run(adoc)
    assert_equal(1, errors.length)
    assert_match /bad_chapter _anchor/, errors[0][:msg]
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
