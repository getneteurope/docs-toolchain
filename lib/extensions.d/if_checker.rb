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
      parsed = adoc.parsed
      errors = []

      # TODO: research why read_lines can be empty
      lines = parsed.reader.read_lines
      lines = parsed.reader.source_lines if lines.empty?

      ifs = {}             # open_if_lineno -> close_if_lineno
      vars = {}            # hash to save ifdef variables
      stack_open = []      # stack of currently open ifs
      unmatched_close = [] # list of closing ifs without an opening counterpart

      lines.each_with_index do |line, lineno|
        if line.start_with?('ifdef::')
          stack_open.push(lineno)
          vars[lineno] = line.split(':').last[0..-3]
          ifs[lineno] = nil
        elsif line.start_with?('endif::')
          open_lineno = stack_open.pop
          if open_lineno.nil? # if no opening part, remember this closing part
            unmatched_close << lineno
          else
            ifs[open_lineno] = lineno
          end
        end
      end

      ifs.select { |_, val| val.nil? }.each do |lineno, _|
        msg = "Mismatched IF: unmatched ifdef found on line #{lineno}: ifdef::#{vars[lineno]}[]"
        errors << create_error(
          msg: msg,
          location: Location.new(parsed.attr('docfile'), lineno)
        )
      end
      unmatched_close.each do |lineno|
        msg = "Mismatched IF: unmatched endif found on line #{lineno}"
        errors << create_error(
          msg: msg,
          location: Location.new(parsed.attr('docfile'), lineno)
        )
      end
      return errors
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::IdChecker.new)
