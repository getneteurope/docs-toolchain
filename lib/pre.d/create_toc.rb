# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require_relative '../config_manager.rb'
require_relative '../utils/adoc.rb'
require_relative '../log/log.rb'
require 'json'

CM = Toolchain::ConfigManager.instance

module Toolchain
  module Pre
    ##
    # Adds modules for preprocessing files.
    class CreateTOC < BaseProcess
      ##
      # Creates a TOC JSON file from an +adoc+ object
      # Default JSON path is taken from +ConfigManager+.
      #
      # Returns toc as json tree +toc_json+
      def run(
        adoc = nil, # Toolchain::Adoc.load_doc(CM.get('index.default.file')),
        json_filepath = CM.get('toc.file')
      )
        # TODO document this bit since it's quite confusing
        stage_log(:pre, '[Create TOC] Starting')
        adoc = Toolchain::Adoc.load_doc(
          CM.get('index.default.file')
        ) if adoc.nil?
        parsed = adoc.parsed
        attributes = adoc.attributes
        lines = parsed.reader.source_lines
        reader = ::Asciidoctor::PreprocessorReader.new(parsed, lines)
        combined_source = reader.read_lines
        doc = ::Asciidoctor::Document.new(
          combined_source,
          catalog_assets: true,
          sourcemap: true,
          safe: :unsafe,
          attributes: attributes
        )
        doc.parse

        stack = [OpenStruct.new(id: 'root', level: -1, children: [])]

        doc.catalog[:refs].keys.each do |r|
          ref = doc.catalog[:refs][r]

          level = ref.level
          title = ref.title
          id = ref.id

          attribs = ref.instance_variable_get(:@attributes)
          is_discrete = (attribs&.fetch(1) == 'discrete')

          next if is_discrete || title.nil?

          current = OpenStruct.new(
            id: id,
            level: level,
            title: title,
            parent: nil,
            children: []
          )
          stack.pop while level <= stack.last.level
          current.parent = stack.last

          # add current element to it's parent's children list
          current.parent.children << current

          # replace parent object now with it's id to avoid loops
          current.parent = current.parent.id
          stack.push current
        end
        toc_openstruct = stack.first
        toc_hash = openstruct_to_hash(toc_openstruct)
        toc_json = JSON.pretty_generate(toc_hash)
        File.open(json_filepath, 'w+') do |json_file|
          json_file.write(toc_json)
        end
        log('TOC', 'File written to: ' + json_filepath, :gray)
        return json_filepath
      end

      private

      ## Takes OpenStruct +object+ and returns +hash+
      # Useful for converting OpenStruct Hash for later conversion to JSON
      #
      def openstruct_to_hash(object, hash = {})
        object.each_pair do |key, value|
          hash[key] = case value
                      when OpenStruct then openstruct_to_hash(value)
                      when Array then value.map { |v| openstruct_to_hash(v) }
                      else value
                      end
        end
        return hash
      end
    end
  end
end

Toolchain::PreProcessManager.instance.register(Toolchain::Pre::CreateTOC.new)
