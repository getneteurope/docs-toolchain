# coding: utf-8
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
      lines = original.reader.read_lines
      # get ids that asciidoctor recognizes as such
      adoc_ids = document.catalog[:refs].keys.to_set
      # parse everything that COULD be an anchor or id manually
      parsed_ids = lines.map do |line|
        # match both long and short ids
        /\[(\[|#)(?<id>[^\]]+)/.match(line) do |m|
        m[:id]
        end
      end.reject(&:nil?).to_set # reject all nil entries

      ids = (adoc_ids | parsed_ids).to_a
      ids.each do |id|
        log('ID', "checking #{id}", :magenta)
        msg = "Illegal character: '#{id}' does not match ID criteria (#{REGEX.inspect})"
        errors << create_error(msg: msg, filename: document.attr('docfile')) unless REGEX.match?(id)
      end
      return errors
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::IdChecker.new)
