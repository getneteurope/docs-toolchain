# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/extension_manager.rb'
require_relative './util.rb'

EM = Toolchain::ExtensionManager

class TestExtensionManager < Test::Unit::TestCase
  def test_register
    EM.instance.register('Test')
    exts = EM.instance.get
    assert_equal(1, exts.length)
    assert_equal('Test', exts.first)
    EM.instance.clear
  end

  def test_next_id
    (1..3).each do |idx|
      id = EM.instance.next_id
      assert_equal(idx, id)
    end
    EM.instance.clear
  end
end
