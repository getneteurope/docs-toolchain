# frozen_string_literal: true

ENV['UNITTEST'] = 'true'
Dir[File.join(__dir__, 'test_*.rb')].each { |f| require f }
