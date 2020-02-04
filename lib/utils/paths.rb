# frozen_string_literal: true

module Toolchain
  ##
  # content_path
  # Returns path to content directory +content_dir_path+.
  #
  def self.content_path(path = nil)
    content_dir_path = Dir.pwd
    content_dir_path = File.join(Dir.pwd, '..') if File.basename(Dir.pwd) == 'toolchain'
    content_dir_path = ENV['GITHUB_WORKSPACE'] \
      if ENV.key?('TOOLCHAIN_TEST') || ENV.key?('GITHUB_ACTIONS')
    content_dir_path = ENV['CONTENT_PATH'] if ENV.key?('CONTENT_PATH')
    # For Unit testing:
    content_dir_path = path unless path.nil?
    return content_dir_path
  end
end