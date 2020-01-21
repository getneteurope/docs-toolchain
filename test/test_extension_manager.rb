# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/extension_manager.rb'

class TestExtensionManager < Test::Unit::TestCase
  def test_register
    em = Toolchain::ExtensionManager.instance
    em.register('Test', false)
    exts = em.get
    assert_equal(1, exts.length)
    assert_equal('Test', exts.first)
  end

  def test_next_id
    (1..3).each do |idx|
      id = Toolchain::ExtensionManager.instance.next_id
      assert_equal(idx, id)
    end
  end
end
