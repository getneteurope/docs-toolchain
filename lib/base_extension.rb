# frozen_string_literal: true

require_relative './extension_manager.rb'
require_relative './utils/paths.rb'

module Toolchain
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
    ##
    # Create an error using +msg+ stating the error at +location+.
    #
    # This method supports further extension through the hash option +extras+.
    #
    # Returns the formatted error according to +Toolchain::ExtensionManager#create_error+.
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
      raise NotImplementedError.new,
        "#{self.class.name}: no implementation for 'run'"
    end
  end
end
