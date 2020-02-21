# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/log/log.rb'
require_relative './util.rb'

class TestLog < Test::Unit::TestCase
  def setup
    # unset env var UNITTEST to enable output of log
    ENV.delete('UNITTEST')
  end

  def teardown
    ENV['UNITTEST'] = 'true'
  end

  def test_log
    outputs = [
      with_captured_stdout { log('TEST', 'This is a test!') },
      with_captured_stdout { log('TEST', 'This is a test!', :red) },
      with_captured_stdout { log('TEST', 'This is a test!', :green, true) }
    ]

    outputs.each do |output|
      assert_match(/TEST/, output)
      assert_true(
        output[0..output.index('!')].end_with?('This is a test!')
      )
    end
  end

  def test_stage_log
    stages = %i[setup test build deploy post notify]
    outputs = []
    stages.each do |stage|
      outputs << with_captured_stdout do
        stage_log(stage, 'This is a test!')
      end
    end
    stages.zip(outputs).each do |stage, output|
      assert_match(stage.to_s.upcase, output)
      assert_true(
        output[0..output.index('!')].end_with?('This is a test!')
      )
    end
  end


  def test_log_error
    output = with_captured_stderr { error('Found error!') }

    assert_match(/ERROR/, output)
    assert_true(
      output[0..output.index('!')].end_with?('Found error!')
    )
  end
end
