# Gemfiles Combinator
#
# installs several Gemfiles defined in gemfiles array
# Use with bundler: bundle install --gemfile=bundle_combined_gemfiles.rb

source 'https://rubygems.org'
gemfiles = ['toolchain/Gemfile', 'Gemfile']
gemfiles.each do |gemfile|
  instance_eval File.read(gemfile) if File.file?(gemfile)
end
