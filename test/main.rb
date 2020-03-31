# frozen_string_literal: true

require 'simplecov'

ENV['UNITTEST'] = 'true'
Dir[File.join(__dir__, 'test_*.rb')].each { |f| require f }
Dir[File.join(__dir__, 'test_*.d', '*.rb')].each { |f| require f }
