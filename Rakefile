require 'rubocop/rake_task'
require 'rubycritic/rake_task'
require 'rdoc/task'
require 'inch/rake'
require 'rake/testtask'
require_relative 'lib/utils/setup.rb'

task default: %w[toolchain:test toolchain:lint]

def toolchain_path
  ENV.key?('TOOLCHAIN_PATH') ? ENV['TOOLCHAIN_PATH'] : File.dirname(__FILE__)
end

namespace :docs do
  @setup_done = false

  desc 'Run through all stages'
  task :all do
    %w[clean test pre build post notify].each { |t| Rake::Task["docs:#{t}"].execute }
  end

  desc 'Clean build directory'
  task :clean do
    ruby "#{toolchain_path}/bin/clean.rb"
  end

  desc 'Run test stage'
  task :test do
    debug = '--debug' if ENV.key?('DEBUG')
    ruby "#{toolchain_path}/bin/test.rb #{debug}" unless ENV.key?('SKIP_RAKE_TEST')
  end

  desc 'Run pre-processing stage'
  task :pre do
    Toolchain::Setup.setup()
    @setup_done = true
    debug = '--debug' if ENV.key?('DEBUG')
    ruby "#{toolchain_path}/bin/pre.rb #{debug}"
  end

  desc 'Run build stage'
  task :build do
    Toolchain::Setup.setup() unless @setup_done
    debug = '--debug' if ENV.key?('DEBUG')
    ruby "#{toolchain_path}/bin/build.rb #{debug}"
  end

  desc 'Run post processing'
  task :post do
    debug = '--debug' if ENV.key?('DEBUG')
    ruby "#{toolchain_path}/bin/post.rb #{debug}"
  end

  desc 'Send notifications'
  task :notify do
    ruby "#{toolchain_path}/bin/notify.rb"
  end
end

namespace :toolchain do
  desc 'Run toolchain unit tests (rake task)'
  Rake::TestTask.new(:testtask) do |task|
    # ENV['UNITTEST'] = 'true'

    task.libs << 'test'
    task.test_files = FileList['test/test_*.rb']
    # task.verbose = true
  end

  desc 'Run toolchain unit tests'
  task :test do
    ruby 'test/main.rb'
  end

  RuboCop::RakeTask.new(:lint) do |task|
    task.options = ['--fail-level', 'E']
  end

  RubyCritic::RakeTask.new(:quality) do |task|
    task.options = '-p /tmp/rubycritic'
    task.options = '-p /tmp/rubycritic --format console --format html --no-browser' \
      if ENV.key?('GITHUB_ACTIONS')
  end

  RDoc::Task.new(
    :rdoc => 'rdoc', :clobber_rdoc => 'rdoc:clean', :rerdoc => 'rdoc:force'
  ) do |task|
    task.rdoc_files.include('bin/', 'lib/')
    task.rdoc_dir = '/tmp/rdoc'
    task.options << '--all'
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
    puts "UNITTEST = #{ENV['UNITTEST']}"
  end
end
