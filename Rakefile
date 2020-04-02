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

FLAGS = "-E utf-8 -I#{toolchain_path}/lib"

def call script
  if ENV.key?('FAST')
    ENV['SKIP_RAKE_TEST'] = 'true'
    ENV['SKIP_HTMLCHECK'] = 'true'
  end
  debug = '--debug' if ENV.key?('DEBUG')
  ruby "#{FLAGS} #{toolchain_path}/#{script} #{debug}"
end

# TASKS
namespace :docs do
  @setup_done = false

  desc 'Run through all stages'
  task :all do
    %w[clean test pre build post notify].each { |t| Rake::Task["docs:#{t}"].execute }
  end

  desc 'Run through all stages without checks and tests'
  task :fast do
    ENV['FAST'] = 'true'
    ENV['SKIP_RAKE_TEST'] = 'true'
    ENV['SKIP_HTMLCHECK'] = 'true'
    Rake::Task['docs:all'].execute
  end

  desc 'Clean build directory'
  task :clean do
    call "bin/clean.rb"
  end

  desc 'Run test stage'
  task :test do
    call "bin/test.rb"
  end

  desc 'Run pre-processing stage'
  task :pre do
    Toolchain::Setup.setup()
    @setup_done = true
    call "bin/pre.rb"
  end

  desc 'Run build stage'
  task :build do
    Toolchain::Setup.setup() unless @setup_done
    call "bin/build.rb"
  end

  desc 'Run post processing'
  task :post do
    call "bin/post.rb"
  end

  desc 'Send notifications'
  task :notify do
    call "bin/notify.rb"
  end

  ###
  # Utils
  namespace :list do
    desc 'List Pre processing actions that will be loaded'
    task :pre do
      call "bin/pre.rb --list"
    end

    desc 'List Post processing actions that will be loaded'
    task :post do
      call "bin/post.rb --list"
    end
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
    call 'test/main.rb'
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
    puts "LOAD_PATH = #{$LOAD_PATH}"
  end
end
