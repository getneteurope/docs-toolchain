require 'rubocop/rake_task'

task default: %w[toolchain:test toolchain:lint]

def toolchain_path
  ENV.key?('TOOLCHAIN_PATH') ? ENV['TOOLCHAIN_PATH'] : File.dirname(__FILE__)
end

namespace :docs do
  desc 'Run test stage'
  task :test do
    debug = '--debug' if ENV.key?('DEBUG')
    ruby "#{toolchain_path}/bin/test.rb #{debug}"
  end

  desc 'Run build stage'
  task :build do
    debug = '--debug' if ENV.key?('DEBUG')
    ruby "#{toolchain_path}/bin/build.rb #{debug}"
  end
end

namespace :toolchain do
  desc 'Run toolchain unit tests'
  task :test do
    ruby 'test/main.rb'
  end

  RuboCop::RakeTask.new(:lint) do |t|
    t.options = ['--fail-level', 'E']
  end
end

namespace :env do
  desc 'Print current env'
  task :print do
    puts "PWD   = #{ENV['PWD']}"
    puts "DEBUG = #{ENV['DEBUG']}"
    puts "TOOLCHAIN_PATH = #{ENV['TOOLCHAIN_PATH']}"
  end
end
