# frozen_string_literal: true

require_relative '../extension_manager.rb'
require_relative '../base_extension.rb'

module Toolchain
  # looks up a list of prohibited patterns
  class PatternBlacklist < BaseExtension
    def run(document, original)
      errors = []
      blacklist_file = '../blacklist.txt'
      blacklist_file = File.open(blacklist_file, 'r')
      blacklist_patterns = blacklist_file.readlines
      blacklist_file.close

      blacklist_patterns.delete_if do |line|
        !line.match? %r{^/(.+)/$}
      end

      blacklist_patterns = blacklist_patterns.map do |pattern|
        Regexp.new pattern.chomp.gsub %r{^/(.+)/$}, '\1'
      end

      lines = original.reader.read_lines
      lines = original.reader.source_lines if lines.empty?

      lines.each_with_index do |line, index|
        blacklist_patterns.each_with_index do |pattern, _p_idx|
          next unless line.match? pattern

          msg = "Illegal pattern in line #{index + 1}: #{pattern.inspect}"
          log('PATTERN', msg)
          errors << create_error(msg: msg, filename: document.attr('docfile'))
        end
      end
      return errors
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::PatternBlacklist.new)
