# frozen_string_literal: true

require_relative './extension_manager.rb'

module Toolchain
  require 'zlib'
  ##
  # content_path
  # Returns path to content directory +content_dir_path+.
  #
  def self.content_path(path = nil)
    content_dir_path = '..'
    content_dir_path = ENV['GITHUB_WORKSPACE'] \
      if ENV.key?('TOOLCHAIN_TEST') || ENV.key?('GITHUB_ACTIONS')
    content_dir_path = ENV['CONTENT_PATH'] if ENV.key?('CONTENT_PATH')
    # For Unit testing:
    content_dir_path = path unless path.nil?
    return content_dir_path
  end

  # Location describes a source location, made up of +filename+ and +lineno+.
  # Params:
  # * +filename+: adoc filename
  # * +lineno+: line number
  Location = Struct.new(:filename, :lineno) do
    ##
    # Returns a String representation of the location
    def to_s
      return "#{filename}:#{lineno}"
    end

    private

    def filename=; end

    def lineno=; end
  end

  # Base class for extensions,
  # all derived extensions must implement the run(document) function
  # and register with the ExtensionManager, e.g.:
  #
  # Toolchain::ExtensionManager.instance.register(Toolchain::ExampleChecker.new)
  #
  class BaseExtension
    def create_error(msg:, location: nil, extras: nil)
      return Toolchain::ExtensionManager.create_error(
        msg: msg, type: self.class.name, location: location, extras: extras
      )
    end

    ##
    # Takes a document (a converted asciidoctor document) as input.
    #
    # Parameters: +_adoc+ contains parsed and original and attributes of Asciidoctor document.
    #
    # If there are no errors, an empty Hash must be returned.
    # Errors can only be created by +create_error+.
    # *DO NOT* create errors manually, use +create_error+ and pass the necessary parameters.
    #
    # Returns an array of Hashes of errors (can be empty if no errors found).
    #
    def run(_adoc)
      raise NotImplementedError.new, "#{self.class.name}: no implementation for 'run'"
    end
  end
end
