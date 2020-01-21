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

      # get ids that asciidoctor recognizes as such
      adoc_ids = converted.catalog[:refs].keys.to_set
      # p (original.instance_variable_get :@attributes).to_a

      require 'pp'

      # parse everything that COULD be an anchor or id manually
      parsed_ids = lines.map do |line|
        pp line
        # match both long and short ids
        /\[(\[|#)(?<id>[^\]]+)/.match(line) do |m|
          m[:id]
        end
      end.reject(&:nil?).to_set # reject all nil entries

      # if parsed id is unresolved attribute, look up attribute and replace
      log('PARSED_IDS', parsed_ids)
      log('ADOC_IDS', adoc_ids)
      # adoc_ids = adoc_ids.map do |pid|
      #   id = pid
      #   log('ID', id)
      #   if ATTR_REGEX.match? pid
      #     log('ID', id + ' looks like it contains an anchor')
      #     r_pid = pid.gsub ATTR_REGEX, '\1'
      #     if attributes.keys.any? r_pid
      #       log('ATTR_FOUND', r_pid, :yellow)
      #       attributes[r_pid]
      #       id = attributes[r_pid]
      #     else
      #       log('ID', id + " not found in attributes:\n" + attributes.inspect)
      #     end
      #   end
      #   id # TODO: fix ugly return
      # end.reject(&:nil?).to_set

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
