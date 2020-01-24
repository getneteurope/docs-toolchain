# frozen_string_literal: true

require_relative '../extension_manager.rb'
require_relative '../base_extension.rb'

module Toolchain
  ##
  # Include Checker
  #
  # Check the number of open and closing IFs
  class IfChecker < BaseExtension
    ##
    # Run the if tests on the given document (+adoc+).
    #
    # Returns a list of errors (can be empty).
    #
    def run(adoc)
      original = adoc.original
      parsed = adoc.parsed

      errors = []

      org_lines = original.reader.source_lines
      pp org_lines
      pp '######################'
      # TODO: research why read_lines can be empty
      lines = parsed.reader.read_lines
      lines = parsed.reader.source_lines if lines.empty?
      pp lines
      pp '######################'

      reader = Asciidoctor::PreprocessorReader.new parsed, lines
      combined_source = reader.read_lines
      pp combined_source

      # errors << create_error(
      #   msg: msg,
      #   location: Location.new(original.attr('docfile'), nil)
      # )
      return errors
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::IdChecker.new)
