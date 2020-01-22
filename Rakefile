require 'rubocop/rake_task'
require 'rubycritic/rake_task'
require 'rdoc/task'
require 'inch/rake'

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

  desc 'Run post processing'
  task :postprocess do
    debug = '--debug' if ENV.key?('DEBUG')
    ruby "#{toolchain_path}/bin/post-process.rb #{debug}"
  end

  desc 'Send notifications'
  task :notify do
    ruby "#{toolchain_path}/bin/notify.rb"
  end
end

namespace :toolchain do
  desc 'Run toolchain unit tests'
  task :test do
    ruby 'test/main.rb'
  end

  RuboCop::RakeTask.new(:lint) do |task|
    task.options = ['--fail-level', 'E']
  end

  RubyCritic::RakeTask.new(:quality) do |task|
    task.options = '-p /tmp/rubycritic'
    task.options = '-p /tmp/rubycritic --mode-ci --format html --format console --no-browser' \
      if ENV.key?('GITHUB_ACTIONS')
  end

  RDoc::Task.new(
    :rdoc => 'rdoc', :clobber_rdoc => 'rdoc:clean', :rerdoc => 'rdoc:force'
  ) do |task|
    task.rdoc_files.include('bin/', 'lib/')
    task.rdoc_dir = 'rdoc'
    task.options = %w[--all -o /tmp/rdoc]
    puts task.options
  end

  namespace :inch do
    Inch::Rake::Suggest.new(:suggest) do |task|
    end

    desc 'Show documentation grade'
    task :grade do
      sh 'inch stats' do
      end
    end
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
