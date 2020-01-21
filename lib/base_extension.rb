# frozen_string_literal: true

require_relative './extension_manager.rb'

module Toolchain
  # Location describes a source location, made up of +filename+ and +lineno+.
  Location = Struct.new(:filename, :lineno) do
    def to_s
      return "#{filename}:#{lineno}"
    end
  end

  # Base class for extensions,
  # all derived extensions must implement the run(document) function
  # and register with the ExtensionManager, e.g.:
  #
  # Toolchain::ExtensionManager.instance.register(Toolchain::ExampleChecker.new)
  #
  class BaseExtension
    ##
    # Creates an error, consisting of the following fields:
    # [id]       continuous ID to identify order of errors
    # [type]     type of error, defaults to the name of the extension
    # [msg]      the error message
    # [location] location of the error, described by +Location+
    # [extras]   for future use, unused right now
    #
    # Only a subset of the keys can be passed to the function:
    # * +msg+
    # * +location+
    # * +extras+
    #
    # Returns the error as Hash.
    #
    def create_error(msg:, location: nil, extras: nil)
      return {
        id: Toolchain::ExtensionManager.instance.next_id,
        type: self.class.name,
        msg: msg,
        location: location,
        extras: extras
      }
    end

    ##
    # Takes a document (a converted asciidoctor document) as input.
    #
    # Parameters: +_document+ is the converted Asciidoctor document, whereas
    #             +_original+ is the original source code of the document.
    #
    # If there are no errors, an empty Hash must be returned.
    # Errors can only be created by +create_error+.
    # *DO NOT* create errors manually, use +create_error+ and pass the necessary parameters.
    #
    # Returns an array of Hashes of errors (can be empty if no errors found).
    #
    def run(_document, _original)
      raise NotImplementedError.new, "#{self.class.name}: no implementation for 'run'"
    end
  end
end
