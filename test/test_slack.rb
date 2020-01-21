# frozen_string_literal: true

require_relative '../lib/notify/slack.rb'

Slack = Toolchain::Notify::Slack

class TestSlackNotify < Test::Unit::TestCase
  def test_add
    msg_file = ENV['SLACK_MSG_FILE'] = '/tmp/slack.test.json'
    Slack.instance.add('Test')
    assert_true(File.exist?(msg_file))
    File.open(msg_file, 'r') do |reader|
      assert_match(/Test/, reader.read)
    end
  end
end
