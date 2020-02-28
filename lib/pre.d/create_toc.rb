# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require_relative '../config_manager.rb'
require_relative '../utils/adoc.rb'
require_relative '../log/log.rb'
require 'json'
require 'nokogiri'

CM = Toolchain::ConfigManager.instance

module Toolchain
  module Pre
    ##
    # Adds modules for preprocessing files.
    class CreateTOC < BaseProcess
      @@multipage_level = CM.get('asciidoc.multipage_level')
      @@default_json_filepath = CM.get('toc.json_file')
      @@default_html_filepath = CM.get('toc.html_file')

      def initialize(priority = 0)
        super(priority)
      end

      ##
      # Creates a TOC JSON file from an +adoc+ object
      # Default JSON path is taken from +ConfigManager+.
      #
      # Saves toc as json tree +toc_json+
      # Saves toc as html code +html_fragment+
      # Returns path to created JSON file +json_filepath+, path to creted HTML fragment file +html_path+ and the TOC Has +toc_hash+
      #
      def run(
        adoc = nil, # Toolchain::Adoc.load_doc(CM.get('asciidoc.index.file')),
        json_filepath = @@default_json_filepath,
        html_filepath = @@default_html_filepath
      )
        # TODO: document this bit since it's quite confusing
        stage_log(:pre, '[Create TOC] Starting')
        if adoc.nil?
          adoc = Toolchain::Adoc.load_doc(
            CM.get('asciidoc.index.file')
          )
        end
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
        ancestors = []

        # for all headings in the adoc document do
        doc.catalog[:refs].keys.each do |r|
          ref = doc.catalog[:refs][r]
          level = ref.level
          title = ref.title
          id = ref.id
          attribs = ref.instance_variable_get(:@attributes)

          # skip discrete headings and headings with a level too high
          is_discrete = attribs&.key?(1) && (attribs&.fetch(1) == 'discrete')
          next if is_discrete || title.nil?

          current = OpenStruct.new(
            id: id,
            level: level,
            title: title,
            parent: nil,
            children: []
          )
          while level <= stack.last.level
            stack.pop 
            ancestors.pop
          end

          current.parent = stack.last


          ancestors << current.parent.id
          founder = ancestors[@@multipage_level - 1] || current.id
          pp '#####'
          pp current.id
          pp founder

          # add current element to it's parent's children list
          current.parent.children << current

          # replace parent object now with it's id to avoid loops
          current.parent = current.parent.id

          current.founder = founder

          # while current.ancestors.length > CM.get('asciidoc.multipage_level')
          #   current.ancestors.pop
          # end
          stack.push current
        end

        # first element of the stack contains the final TOC tree
        toc_openstruct = stack.first

        # create JSON from TOC tree
        toc_hash = openstruct_to_hash(toc_openstruct)
        toc_json = JSON.pretty_generate(toc_hash)
        File.open(json_filepath, 'w+') do |json_file|
          json_file.write(toc_json)
        end
        log('TOC', 'JSON written to: ' + json_filepath, :gray)

        # create Nokogiri HTML document Object from TOC tree
        toc_html_dom = Nokogiri::HTML.fragment('<div id="toc_wrapper"><div id="toc"></div>' + "\n" + '</div>')
        toc_html_dom.at_css('#toc') << generate_html_from_toc(toc_openstruct.children)

        # convert Nokogiri HTML Object to string
        toc_html_string = toc_html_dom.to_xhtml(indent: 3) 
        File.open(html_filepath, 'w+') do |html_file|
          html_file.write(toc_html_string)
        end
        log('TOC', 'HTML fragment written to: ' + html_filepath, :gray)
        pp toc_hash
        return json_filepath, html_filepath, toc_hash
      end

      private

      ## Recursivelz generates a HTML fragment for the Table Of Content
      # Takes OpenStruct of +toc_elements+ as input
      # Returns HTML code fragment as string Nokogiri Object +fragment+
      #
      def generate_html_from_toc(toc_elements)
        fragment = Nokogiri::HTML.fragment('<ul></ul>')
        toc_elements.each do |e|
          ## TODO rewrite this and do it in object creation
          # ancestors = e.ancestors.split(',')
          # generations = ancestors.length
          # founding_father_idx = 
          root_file = e.founder == 'root' ? '' : e.founder + '.html'
          fragment_string = Nokogiri::HTML.fragment('<li id="toc_' + e.id + '"></li>' + "\n")
          fragment_string.at('li') << "\n" + '  <a href="' + root_file + '#' + e.id + '">' + e.title + '</a>' + "\n"
          # fragment_string.at('li') << if e.level < 1
          #   "\n" + '  <a href="' + e.id + '">' + e.title + '</a>' + "\n"
          # else
          #   "\n" + '  <a href="' + root_file + '#' + e.id + '">' + e.title + '</a>' + "\n"
          # end

          # if element has child elements, add them to current list item
          fragment_string.at('li') << generate_html_from_toc(e.children) unless e.children.empty?
          fragment.at('ul') << fragment_string
        end
        return fragment
      end

      ## Takes OpenStruct +object+ and returns +hash+
      # Useful for converting OpenStruct Hash for later conversion to JSON
      #
      def openstruct_to_hash(object, hash = {})
      return object unless object.is_a? OpenStruct
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
