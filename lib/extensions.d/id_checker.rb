# frozen_string_literal: true

require_relative '../extension_manager.rb'
require_relative '../base_extension.rb'

module Toolchain
  # ID Checker
  # check IDs according to a stricter standard than the default Asciidoctor standard
  class IdChecker < BaseExtension
    REGEX = /^[A-Za-z0-9_]+$/.freeze
    def run(document, original)
      errors = []
      # TODO: research why read_lines can be empty
      lines = original.reader.read_lines
      lines = original.reader.source_lines if lines.empty?

      # get ids that asciidoctor recognizes as such
      adoc_ids = document.catalog[:refs].keys.to_set

      # parse everything that COULD be an anchor or id manually
      parsed_ids = lines.map do |line|
        # match both long and short ids
        /\[(\[|#)(?<id>[^\]]+)/.match(line) do |m|
          m[:id]
        end
      end.reject(&:nil?).to_set # reject all nil entries

      (adoc_ids | parsed_ids).to_a.each do |id|
        log('ID', "checking #{id}", :magenta)
        msg = "Illegal character: '#{id}' does not match ID criteria (#{REGEX.inspect})"
        next if REGEX.match?(id)

        errors << create_error(
          msg: msg,
          location: Location.new(document.attr('docfile'), nil)
        )
      end
      return errors
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::IdChecker.new)
