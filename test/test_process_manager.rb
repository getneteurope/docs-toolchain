# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/base_process.rb'
require_relative '../lib/process_manager.rb'
require_relative '../lib/config_manager.rb'
require_relative './util.rb'

PreM = Toolchain::PreProcessManager.instance
PostM = Toolchain::PostProcessManager.instance

class MyProcess < Toolchain::BaseProcess
  def initialize(num)
    @num = num
  end

  def run
    return @num
  end
end

def generate(cls = Toolchain::BaseProcess)
  (1..3).map do |i|
    cls.new(i)
  end
end

# TODO add test that loads extensions from default directory AND custom directory
class TestPreProcessManager < Test::Unit::TestCase
  CONFIG = { 'processes' => { 'pre' => { 'enable' => ['BaseProcess'] } } }

  def setup
    PreM.clear
    with_tempfile(CONFIG.to_yaml) do |config|
      ::Toolchain::ConfigManager.instance.load(config)
    end
  end

  def teardown
    PreM.clear
  end

  def test_register
    generate.each do |ref_p|
      PreM.register(ref_p)
    end
    procs = PreM.get
    assert_equal(3, procs.length)
    assert_equal((1..3).to_a.reverse, procs.map(&:priority))
    assert_equal(3, procs.first.priority)
  end

  def test_process_run_fail
    generate.each { |ref_p| PreM.register(ref_p) }
    assert_raise(NotImplementedError) do
      PreM.run
    end
  end

  def test_process_run_success
    generate(MyProcess).each { |ref_p| PreM.register(ref_p) }
    assert_nothing_raised(NotImplementedError) do
      PreM.run
    end
  end

  def test_return_code
    assert_equal(0, PreM.run)
    PreM.return_code
    assert_equal(10, PreM.run)
    PreM.return_code(23)
    assert_equal(23, PreM.run)
    PreM.return_code(-1)
    assert_equal(-1, PreM.run)
  end
end

# TODO add test that loads extensions from default directory AND custom directory
class TestPostProcessManager < Test::Unit::TestCase
  CONFIG = { 'processes' => { 'post' => { 'enable' => ['BaseProcess'] } } }

  def setup
    PostM.clear
    with_tempfile(CONFIG.to_yaml) do |config|
      ::Toolchain::ConfigManager.instance.load(config)
    end
  end

  def teardown
    PostM.clear
  end

  def test_register
    generate.each do |ref_p|
      PostM.register(ref_p)
    end
    procs = PostM.get
    assert_equal(3, procs.length)
    assert_equal((1..3).to_a.reverse, procs.map(&:priority))
    assert_equal(3, procs.first.priority)
  end

  def test_process_run_fail
    generate.each { |ref_p| PostM.register(ref_p) }
    assert_raise(NotImplementedError) do
      PostM.run
    end
  end

  def test_process_run_success
    generate(MyProcess).each { |ref_p| PreM.register(ref_p) }
    assert_nothing_raised(NotImplementedError) do
      PreM.run
    end
  end

  def test_return_code
    assert_equal(0, PostM.run)
    PostM.return_code
    assert_equal(10, PostM.run)
    PostM.return_code(23)
    assert_equal(23, PostM.run)
    PostM.return_code(-1)
    assert_equal(-1, PostM.run)
  end
end

class TestProcess < Test::Unit::TestCase
  PRIO = 10
  def test_run
    proc = ::Toolchain::BaseProcess.new(PRIO)
    assert_equal(proc.priority, PRIO)
    assert_raise(NotImplementedError) do
      proc.run
    end
  end
end
