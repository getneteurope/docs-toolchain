# frozen_string_literal: true

require_relative '../extension_manager.rb'
require_relative '../base_extension.rb'

module Toolchain
  # ID Checker
  # check IDs according to a stricter standard than the default Asciidoctor standard
  class IdChecker < BaseExtension
    ID_PATTERN_REGEX = /^[A-Za-z0-9_]+$/.freeze
    ATTR_REGEX = /^\{(.+)\}$/.freeze

    def run(adoc)
      original = adoc.original
      converted = adoc.converted
      attributes = adoc.attributes

      errors = []
      # TODO: research why read_lines can be empty
      lines = converted.reader.read_lines
      lines = converted.reader.source_lines if lines.empty?
      
      reader = Asciidoctor::PreprocessorReader.new converted, lines
      combined_source = reader.read_lines

      doc = Asciidoctor::Document.new combined_source, safe: :unsafe, attributes: attributes
      doc.convert
      adoc_ids = doc.catalog[:refs].keys.to_set

      # parse everything that COULD be an anchor or id manually
      parsed_ids = combined_source.map do |line|
        # match both long and short ids
        /\[(\[|#)(?<id>[^\]]+)/.match(line) do |m|
          m[:id]
        end
      end.reject(&:nil?).to_set # reject all nil entries

      # if parsed id is unresolved attribute, look up attribute and replace
      parsed_ids = parsed_ids.map do |pid|
        id = pid
        if ATTR_REGEX.match? pid
          r_pid = pid.gsub ATTR_REGEX, '\1'
          if attributes.keys.any? r_pid
            attributes[r_pid]
            id = attributes[r_pid]
          end
        end
        id # TODO: fix ugly return
      end.reject(&:nil?).to_set

      (adoc_ids | parsed_ids).to_a.each do |id|
        log('ID', "checking #{id}", :magenta)
        msg = "Illegal character: '#{id}' does not match ID criteria (#{ID_PATTERN_REGEX.inspect})"
        errors << create_error(msg: msg, filename: original.attr('docfile')) unless ID_PATTERN_REGEX.match?(id)
      end
      return errors
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::IdChecker.new)
