require 'rubocop/rake_task'

task default: %w[lint test]

namespace :docs do
  task :test do
    toolchain_path = ENV.has_key?('TOOLCHAIN_PATH') ? ENV['TOOLCHAIN_PATH'] : ENV['PWD']
    ruby "#{toolchain_path}/stages/test/ruby/main.rb"
  end
end

namespace :toolchain do
  task :test do
    ruby 'tests/ruby/main.rb'
  end

  RuboCop::RakeTask.new(:lint) do |t|
    t.options = ['--fail-level', 'E']
  end
end
