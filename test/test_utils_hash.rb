# frozen_string_literal: true

require 'test/unit'
require 'ostruct'
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

class TestOpenStructToHash < Test::Unit::TestCase
  DEFAULT = { a: 1, b: { ba: 21, bb: 22, bc: nil }, c: 'c', d: 'ddd' }.freeze
  def test_convert
    ostruct = OpenStruct.new(DEFAULT)
    ref = ::Toolchain::Hash.openstruct_to_hash(ostruct)
    assert_equal(DEFAULT, ref)
    assert_equal(DEFAULT, ostruct.to_h)
  end
end
