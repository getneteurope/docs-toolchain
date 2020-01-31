# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/base_process.rb'
require_relative '../lib/process_manager.rb'
require_relative './util.rb'

PreM = Toolchain::PreProcessManager.instance
PostM = Toolchain::PostProcessManager.instance

def generate
  (1..3).map do |i|
    Toolchain::BaseProcess.new(i)
  end
end

class TestPreProcessManager < Test::Unit::TestCase
  def setup
    PreM.clear
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
end

class TestPostProcessManager < Test::Unit::TestCase
  def setup
    PostM.clear
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
end
