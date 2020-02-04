# frozen_string_literal: true

require_relative '../extension_manager.rb'
require_relative '../base_extension.rb'

module Toolchain
  ##
  # Pattern Checker
  #
  # Checks the text against a predefined list of patterns which are not allowed.
  class PatternBlacklist < BaseExtension
    ##
    # Run the Pattern tests on the given document (+adoc+).
    # Illegal patterns are loaded from +blacklist_file+.
    #
    # Returns a list of errors (can be empty).
    #
    def run(adoc, blacklist_file = '../blacklist.txt')
      original = adoc.original
      parsed = adoc.parsed
      attributes = adoc.attributes
      errors = []
      unless File.exist?(blacklist_file)
        log(
          'PATTERN',
          "Blacklist file '#{blacklist_file}' not found. Skipping this test.",
          :magenta
        )
        return errors
      end
      blacklist_file = File.open(blacklist_file, 'r')
      blacklist_patterns = blacklist_file.readlines
      blacklist_file.close

      blacklist_patterns.delete_if { |line| !line.match? %r{^/(.+)/$} }

      blacklist_patterns = blacklist_patterns.map do |pattern|
        Regexp.new(pattern.chomp.gsub(%r{^/(.+)/$}, '\1'))
      end

      original.reader.source_lines.each_with_index do |line, index|
        blacklist_patterns.each_with_index do |pattern, _p_idx|
          next unless line.match? pattern

          msg = "Illegal pattern in line #{index + 1}: #{pattern.inspect}"
          log('PATTERN', msg, color: :magenta)
          errors << create_error(
            msg: msg,
            location: Location.new(parsed.attr('docfile'), nil)
          )
        end
      end
      return errors
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::PatternBlacklist.new)
