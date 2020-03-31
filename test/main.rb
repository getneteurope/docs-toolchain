# frozen_string_literal: true

require 'simplecov'
require 'simplecov-lcov'

SimpleCov::Formatter::LcovFormatter.config.single_report_path = 'coverage/lcov.info'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter
])

SimpleCov.start do |config|
  add_filter 'test/'
  add_filter 'lib/stages/'
  add_filter 'lib/notify/slack.rb' # not feasible to test
end


ENV['UNITTEST'] = 'true'
Dir[File.join(__dir__, 'test_*.rb')].each { |f| require f }
Dir[File.join(__dir__, 'test_*.d', '*.rb')].each { |f| require f }
