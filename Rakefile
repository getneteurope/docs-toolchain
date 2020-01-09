require 'rubocop/rake_task'

task default: %w[lint test]

task :build do
  ruby 'stages/test/ruby/main.rb'
end

task :test do
  ruby 'tests/ruby/main.rb'
end

RuboCop::RakeTask.new(:lint) do |t|
  t.options = ['--fail-level', 'E']
end

