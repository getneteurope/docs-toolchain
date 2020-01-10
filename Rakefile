require 'rubocop/rake_task'

task default: %w[toolchain:lint toolchain:test]

namespace :docs do
  desc 'Run test stage'
  task :test do
    toolchain_path = ENV.key?('TOOLCHAIN_PATH') ? ENV['TOOLCHAIN_PATH'] : ENV['PWD']
    debug = '--debug' if ENV.key?('DEBUG')
    ruby "#{toolchain_path}/stages/test/ruby/main.rb #{debug}"
  end
end

namespace :toolchain do
  desc 'Run unit tests'
  task :test do
    ruby 'tests/ruby/main.rb'
  end

  RuboCop::RakeTask.new(:lint) do |t|
    t.options = ['--fail-level', 'E']
  end
end
