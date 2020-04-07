# frozen_string_literal: true

require 'test/unit'
require_relative '../../lib/extensions.d/pattern_blacklist.rb'
require_relative '../util.rb'

class TestPatternBlacklist < Test::Unit::TestCase
  def test_pattern_blacklist
    adoc = '= Bad lines

======= too long heading
WPP
document-center

In this paragraph there is a bad_word. Oh no!

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
    blacklist_filepath = write_tempfile('blacklist_patterns.txt', blacklist_patterns)
    adoc = init(adoc, "#{self.class.name}_#{__method__}", 'test_toolchain_pattern_blacklist.adoc')
    errors = Toolchain::PatternBlacklist.new.run(adoc, blacklist_filepath)
    assert_equal(4, errors.length)
  end

  def test_no_blacklist
    adoc = init(adoc, "#{self.class.name}_#{__method__}", 'test_toolchain_pattern_blacklist.adoc')
    errors = Toolchain::PatternBlacklist.new.run(adoc, '/does/not/exist.txt')
    assert_empty(errors)
  end
end
