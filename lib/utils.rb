module Toolchain
  @@content_path

  ##
  # Sets content path across all instances
  #
  def initialize
    content_dir_path = '..'
    content_dir_path = ENV['GITHUB_WORKSPACE'] \
      if ENV.key?('TOOLCHAIN_TEST') || ENV.key?('GITHUB_ACTIONS')
    content_dir_path = ENV['CONTENT_PATH'] if ENV.key?('CONTENT_PATH')
    @@content_path = content_dir_path
  end

  ##
  # Returns path to content directory +@@content_path+.
  #
  def self.content_path(path = nil)
    @@content_path unless path.nil?
    path
  end
end

Dir['utils/*.rb'].each { |f| require f }
