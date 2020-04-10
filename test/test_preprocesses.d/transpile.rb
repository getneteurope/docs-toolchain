# frozen_string_literal: true

require 'test/unit'
require 'json'
require 'fileutils'
require_relative '../../lib/pre.d/transpile_js.rb'
require_relative '../util.rb'
require 'errors'

class TestTranspileJS < Test::Unit::TestCase
  JS = ['[1, 2, 3].map(n => n ** 2);', 'var [a,,b] = [1,2,3];']

  def setup
    @dir = Dir.mktmpdir
    @js_dir = File.join(@dir, 'js')
    FileUtils.mkdir_p(@js_dir)
    JS.each_with_index do |content, idx|
      filename = File.join('js', "js-#{idx}.js")
      write_tempfile(filename, content, prefix: '', path: @dir)
    end

    ENV['BUILD_PATH'] = @dir
  end

  def teardown
    ENV.delete('BUILD_PATH')
    FileUtils.remove_entry(@dir)
  end

  def test_run
    Toolchain::Pre::TranspileJS.new.run
    Dir[File.join(@js_dir, '*.js')] do |jsfile|
      content = IO.readlines(jsfile, chomp: true)
      assert_equal('"use strict;"', content.first)
    end
  end

  # Ignore JS files in subfolders.
  def test_ignore
    vendor_dir = File.join(@js_dir, 'vendor')
    Dir.mkdir(vendor_dir)
    FileUtils.mv(Dir[File.join(@js_dir, '*.js')], vendor_dir)
    Toolchain::Pre::TranspileJS.new.run
    Dir[File.join(@js_dir, '*.js')].zip(JS) do |jsfile, script|
      content = File.read(jsfile)
      assert_equal(script, content)
    end
  end
end
