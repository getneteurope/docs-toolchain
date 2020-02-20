# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require 'json'

module Toolchain
  module Pre
    ##
    # Adds modules for preprocessing files.
    class CreateTOC < BaseProcess
      ##
      # Creates a TOC json file from an +adoc+ object
      # Default json path is taken from config
      #
      # Returns toc as json tree +toc_json+
      def run(adoc, json_filepath = Toolchain::ConfigManager.instance.get('toc.file'))
        parsed = adoc.parsed
        attributes = adoc.attributes
        lines = parsed.reader.source_lines
        reader = ::Asciidoctor::PreprocessorReader.new parsed, lines
        combined_source = reader.read_lines
        doc = ::Asciidoctor::Document.new combined_source, 
          catalog_assets: true,
          sourcemap: true,
          safe: :unsafe,
          attributes: attributes
        doc.parse

        stack = [OpenStruct.new(id: 'root', level: -1, children: [])]

        doc.catalog[:refs].keys.each do |r|
          ref = doc.catalog[:refs][r]
          level = ref.level
          title = ref.title
          id = ref.id
          attribs = ref.instance_variable_get(:@attributes)
          isDiscrete = (attribs&.fetch(1) == 'discrete')
          if isDiscrete
            log('TOC', 'ID ' + id + ' is discrete', :grey)
            next
          end
          if title.nil?
            log('TOC', 'ID ' + id + ' is invalid', :red)
            next
          end
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
        json_file = File.open(json_filepath, 'w+')
        begin
          json_file.write(toc_json)
        ensure
          json_file.close
        end
        log('TOC', 'File written to; ' + json_filepath, :gray)
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
      hash
      end
    end
  end
end

Toolchain::PreProcessManager.instance.register(Toolchain::Pre::CreateTOC.new)