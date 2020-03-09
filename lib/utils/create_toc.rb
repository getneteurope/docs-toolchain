# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require_relative '../config_manager.rb'
require_relative '../utils/adoc.rb'
require_relative '../log/log.rb'
require 'json'
require 'nokogiri'
require 'fileutils'

module Toolchain
  module Adoc
    ##
    # Adds modules for preprocessing files.
    class CreateTOC < BaseProcess

      def initialize(priority = 0)
        super(priority)
        @multipage_level = CM.get('asciidoc.multipage_level')
        @default_json_filepath = File.join(
          ::Toolchain.build_path,
          CM.get('toc.json_file'))
        @default_html_filepath = File.join(
          ::Toolchain.build_path,
          CM.get('toc.html_file'))
      end

      ##
      # Creates a TOC JSON file from an Asciidoctor +catalog+ object
      # Default JSON path is taken from +ConfigManager+.
      #
      # Saves toc as json tree +toc_json+
      # Saves toc as html code +html_fragment+
      # Returns path to created JSON file +json_filepath+, path to creted HTML fragment file +html_path+ and the TOC Has +toc_hash+
      #
      def run(
        catalog,
        json_filepath = @default_json_filepath,
        html_filepath = @default_html_filepath
      )
        FileUtils.mkdir_p(File.dirname(@default_json_filepath))
        FileUtils.mkdir_p(File.dirname(@default_html_filepath))
        stage_log(:pre, 'Create TOC')
        stack = [OpenStruct.new(id: 'root', level: -1, children: [])]
        ancestors = []

        # for all headings in the adoc document do
        catalog[:refs].keys.each do |r|
          ref = catalog[:refs][r]
          next unless ref.is_a? Asciidoctor::Section
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
            label: nil,
            parent: nil,
            parents: [],
            children: []
          )
          while level <= stack.last.level
            stack.pop
            ancestors.pop
          end
          current.parent = stack.last
          ancestors << current.parent.id
          founder = ancestors[@multipage_level] || current.id

          # add current element to it's parent's children list
          current.parent.children << current

          stack.each do |sect|
            title = sect.title
            next if title.nil?
            current.parents << title
            current.label = title if ['REST', 'WPP v1', 'WPP v2'].any? do |keyword|
              title.include?(keyword)
            end
          end
          # replace parent object now with it's id to avoid loops
          current.parent = current.parent.id
          current.founder = founder
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

        # create Nokogiri HTML document Object from TOC tree
        # class and id same as default asciidoctor html5 converter with enabled TOC for drop-in replacement
        toc_html_dom = Nokogiri::HTML.fragment('<div id="toc" class="toc2"></div>' + "\n")
        toc_html_dom.at_css('#toc') << generate_html_from_toc(toc_openstruct.children)

        # convert Nokogiri HTML Object to string
        toc_html_string = toc_html_dom.to_xhtml(indent: 3)
        File.open(html_filepath, 'w+') do |html_file|
          html_file.write(toc_html_string)
        end
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
          root_file = e.founder == 'root' ? '' : e.founder + '.html'
          level = e.level || 0
          fragment_string = Nokogiri::HTML.fragment('<li id="toc_' + e.id + '" data-level="' + level.to_s + '"></li>' + "\n")
          fragment_string.at('li') << "\n" + '  <a href="' + root_file.to_s + (e.founder == e.id ? '' : '#' + e.id)+ '">' + e.title + '</a>' + "\n"

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
