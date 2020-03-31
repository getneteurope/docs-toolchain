# frozen_string_literal: true

if ENV.key?('GITHUB_ACTIONS')
  require 'coveralls'
  Coveralls.wear!
else
  require 'simplecov'
end

ENV['UNITTEST'] = 'true'
Dir[File.join(__dir__, 'test_*.rb')].each { |f| require f }
Dir[File.join(__dir__, 'test_*.d', '*.rb')].each { |f| require f }
