require 'rubocop/rake_task'

task default: %w[toolchain:lint toolchain:test]

def get_toolchain_path
  ENV.key?('TOOLCHAIN_PATH') ? ENV['TOOLCHAIN_PATH'] : ENV['PWD']
end

namespace :docs do
  desc 'Run test stage'
  task :test do
    toolchain_path = get_toolchain_path
    debug = '--debug' if ENV.key?('DEBUG')
    ruby "#{toolchain_path}/stages/test/main.rb #{debug}"
  end

  desc 'Run build stage'
  task :build do
    toolchain_path = get_toolchain_path
    debug = '--debug' if ENV.key?('DEBUG')
    ruby "#{toolchain_path}/stages/build/main.rb #{debug}"
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
