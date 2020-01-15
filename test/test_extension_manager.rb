# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/extension_manager.rb'

class TestExtensionManager < Test::Unit::TestCase
  def test_register
    Toolchain::ExtensionManager.instance.register('Test', false)
    assert_equal(1, Toolchain::ExtensionManager.instance.get.length)
    assert_equal('Test', Toolchain::ExtensionManager.instance.get.first)
  end
end
