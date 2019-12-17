Gemfile

source 'https://rubygems.org'
gemfiles = [ 'dependencies/Gemfile', '../dependencies/Gemfile' ]
gemfiles.each do |gemfile|
    instance_eval File.read(gemfile)
  end
end
