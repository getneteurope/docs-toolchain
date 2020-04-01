# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/extension_manager.rb'
require_relative '../lib/config_manager.rb'
require_relative './util.rb'

EM = Toolchain::ExtensionManager.instance
CM = Toolchain::ConfigManager.instance

class TestAccept
end

class TestDeny
end

class TestExtensionManager < Test::Unit::TestCase

  CONFIG = %q(
extensions:
    enable:
        - TestAccept
  )

  def test_register
    with_tempfile(CONFIG) { |conf| CM.load(conf) }

    EM.register(TestAccept.new)
    exts = EM.get
    assert_equal(1, exts.length)
    assert_equal(TestAccept.name, exts.first.class.name)
    EM.clear
  end

  def test_register_deny
    with_tempfile(CONFIG) { |conf| CM.load(conf) }

    EM.register(TestAccept.new)
    EM.register(TestDeny.new)
    exts = EM.get
    assert_equal(1, exts.length)
    assert_equal(TestAccept.name, exts.first.class.name)
    EM.clear
    CM.clear
  end

  def test_next_id
    (1..3).each do |idx|
      id = EM.next_id
      assert_equal(idx, id)
    end
    EM.clear
  end
end
