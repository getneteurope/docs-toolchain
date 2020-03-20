# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do |config|
  add_filter 'test/'
  add_filter 'lib/stages/'
  add_filter 'lib/notify/slack.rb' # not feasible to test
end

ENV['UNITTEST'] = 'true'
Dir[File.join(__dir__, 'test_*.rb')].each { |f| require f }
