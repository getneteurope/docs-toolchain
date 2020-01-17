# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

ENV['UNITTEST'] = 'true'
Dir[File.join(__dir__, 'test_*.rb')].each { |f| require f }
