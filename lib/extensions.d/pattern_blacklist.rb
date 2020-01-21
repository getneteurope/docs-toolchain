# frozen_string_literal: true

require_relative '../extension_manager.rb'
require_relative '../base_extension.rb'

module Toolchain
  # looks up a list of prohibited patterns
  class PatternBlacklist < BaseExtension
    def run(document, original, blacklist_file = '../blacklist.txt')
      errors = []
      unless File.exist?(blacklist_file)
        log(
          'PATTERN',
          "Blacklist file '#{blacklist_file}' not found. Skipping this test.",
          color: :magenta
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
          errors << create_error(msg: msg, filename: document.attr('docfile'))
        end
      end
      return errors
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::PatternBlacklist.new)
