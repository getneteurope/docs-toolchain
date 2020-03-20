# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/utils/hash.rb'

class TestHash < Test::Unit::TestCase
  DEFAULT = { a: true, b: false, c: 'Remove' }.freeze
  REF = { a: true, b: false }.freeze
  def test_except!
    hsh = DEFAULT.dup
    hsh.except!(%i[c])
    assert_equal(REF, hsh)
  end

  def test_except
    hsh = DEFAULT.clone
    assert_equal(REF, hsh.except(%i[c]))
  end

  def test_only!
    hsh = DEFAULT.dup
    hsh.only!(%i[a b])
    assert_equal(REF, hsh)
  end

  def test_only
    hsh = DEFAULT.clone
    assert_equal(REF, hsh.only(%i[a b]))
  end
end
