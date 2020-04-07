# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/utils/paths.rb'

class TestPaths < Test::Unit::TestCase
  def test_content_path
    ENV['CONTENT_PATH'] = 'test_env'
    assert_equal('test_env', ::Toolchain.content_path)
    ENV.delete('CONTENT_PATH')
    ENV['GITHUB_ACTIONS'] = 'true'
    ENV['GITHUB_WORKSPACE'] = 'test_workspace'
    assert_equal('test_workspace', ::Toolchain.content_path)
    ENV.delete('GITHUB_ACTIONS')
    ENV.delete('GITHUB_WORKSPACE')
  end

  def test_document_root
    ENV['CONTENT_PATH'] = 'test'
    assert_equal('test/content', ::Toolchain.document_root)
    ENV.delete('CONTENT_PATH')
  end

  def test_toolchain_path
    ENV['TOOLCHAIN_PATH'] = 'test_env'
    assert_equal('test_env', ::Toolchain.toolchain_path)
    ENV.delete('TOOLCHAIN_PATH')
  end

  def test_build_path
    config = { 'build' => { 'dir' => 'test_dir' } }
    with_tempfile(config.to_yaml) do |tf|
      ::Toolchain::ConfigManager.instance.load(tf)
    end
    assert_equal('test_dir', ::Toolchain.build_path)
  end

  def test_html_path
    config = { 'build' => { 'html' => { 'dir' => 'test_html_dir' } } }
    with_tempfile(config.to_yaml) do |tf|
      ::Toolchain::ConfigManager.instance.load(tf)
    end
    assert_equal('test_html_dir', ::Toolchain.html_path)
  end

end
