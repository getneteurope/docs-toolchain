# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/config_manager.rb'
require_relative './util.rb'

class TestConfigManager < Test::Unit::TestCase
  def test_load
    config = { 'a' => { 'b' => 'c' }, 'd' => 'e' }
    # use tempfile to load config into ConfigManager
    with_tempfile(config.to_yaml) do |tf|
      Toolchain::ConfigManager.instance.load(tf)
    end
    assert_equal(config, Toolchain::ConfigManager.instance.get)
  end

  def test_update
    config = { 'a' => { 'b' => 'c' }, 'd' => 'e' }
    update = { 'a' => { 'f' => 'g' }, 'd' => 'h' }
    ref = { 'a' => { 'b' => 'c', 'f' => 'g' }, 'd' => 'h' }
    # use tempfile to load config into ConfigManager
    with_tempfile(config.to_yaml) do |tf|
      Toolchain::ConfigManager.instance.load(tf)
    end
    # use tempfile to update config in ConfigManager
    with_tempfile(update.to_yaml) do |tf|
      Toolchain::ConfigManager.instance.update(tf)
    end
    assert_equal(ref, Toolchain::ConfigManager.instance.get)
  end

  def test_get
    config = { 'a' => { 'b' => 'c' }, 'd' => 'e' }
    # use tempfile to load config into ConfigManager
    with_tempfile(config.to_yaml) do |tf|
      Toolchain::ConfigManager.instance.load(tf)
    end
    assert_equal('c', Toolchain::ConfigManager.instance.get('a.b'))
  end

  def test_get_nil
    config = { 'a' => { 'b' => 'c' }, 'd' => 'e' }
    # use tempfile to load config into ConfigManager
    with_tempfile(config.to_yaml) do |tf|
      Toolchain::ConfigManager.instance.load(tf)
    end
    assert_nil(Toolchain::ConfigManager.instance.get('x.y'))
  end
end
