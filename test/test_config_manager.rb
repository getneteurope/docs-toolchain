# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/config_manager.rb'
require_relative './util.rb'


class TestConfigManager < Test::Unit::TestCase
  CONFIG = { 'a' => { 'b' => 'c' }, 'd' => 'e' }

  def setup
    Toolchain::ConfigManager.instance.clear
    # use tempfile to load config into ConfigManager
    with_tempfile(CONFIG.to_yaml) do |tf|
      Toolchain::ConfigManager.instance.load(tf)
    end
  end

  def teardown
    Toolchain::ConfigManager.instance.clear
  end

  def test_load
    assert_equal(CONFIG, Toolchain::ConfigManager.instance.get)
  end

  def test_load_fallback
    Dir.mktmpdir do |tmpdir|
      config = File.join(tmpdir, 'config', 'default.yaml')
      Dir.mkdir(File.dirname(config))
      File.open(config, 'w+') do |conf|
        conf.puts(CONFIG.to_yaml)
      end

      Toolchain::ConfigManager.instance.clear
      # force fallback config
      ENV['TOOLCHAIN_PATH'] = tmpdir
      Toolchain::ConfigManager.instance.load('filethatdoesnotexist')
      ENV.delete('TOOLCHAIN_PATH')
    end
    assert_equal(CONFIG, Toolchain::ConfigManager.instance.get)
  end

  def test_update
    update = { 'a' => { 'f' => 'g' }, 'd' => 'h' }
    ref = { 'a' => { 'b' => 'c', 'f' => 'g' }, 'd' => 'h' }
    # use tempfile to update config in ConfigManager
    with_tempfile(update.to_yaml) do |tf|
      Toolchain::ConfigManager.instance.update(tf)
    end
    assert_equal(ref, Toolchain::ConfigManager.instance.get)
  end

  def test_get
    assert_equal('c', Toolchain::ConfigManager.instance.get('a.b'))
  end

  def test_get_nil
    assert_nil(Toolchain::ConfigManager.instance.get('x.y'))
  end

  def test_clear
    assert_not_nil(Toolchain::ConfigManager.instance.get)
    Toolchain::ConfigManager.instance.clear
    assert_nil(Toolchain::ConfigManager.instance.get)
  end

  def test_contains
    assert_true(Toolchain::ConfigManager.instance.contains?('a.b', 'c'))
    assert_false(Toolchain::ConfigManager.instance.contains?('a.b', 'd'))
    assert_false(Toolchain::ConfigManager.instance.contains?('a.b.z', 'z'))
  end
end
