# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require_relative '../utils/paths.rb'
require_relative '../utils/adoc.rb'
require 'v8'
require 'nokogiri'
require 'asciidoctor'

module Toolchain
  module Pre
    ##
    # Adds modules for preprocessing files.
    class CompileSearchIndex < BaseProcess
      SELECTOR_SECTIONS = '.sect2, .sect3'
      SELECTOR_HEADINGS = 'h2, h3, h4'
      SELECTOR_PARAGRAPHS = 'p'
      def initialize; end

      ##
      # Takes adoc Struct +adoc+
      # Returns .json search index for lunr
      def run(adoc = nil)
        unless adoc.nil?
          adoc = Toolchain::Adoc.load_doc(
            File.join(Toolchain.content_path, 'content', 'index.adoc')
          )
        end
        adoc = Toolchain::Adoc.load_doc(adoc) if adoc.is_a?(String)

        full_html = convert_full_to_html(adoc)
        return generate_index_json(full_html)
      end

      private

      ##
      # Returns Asciidoctor::Document +full_doc+ with all includes included.
      #
      def combine_to_single_doc(adoc)
        parsed_adoc = adoc.parsed
        lines = parsed_adoc.reader.source_lines
        reader = ::Asciidoctor::PreprocessorReader.new(parsed_adoc, lines)
        combined_source = reader.read_lines
        return ::Asciidoctor::Document.new(
          combined_source, safe: :unsafe, attributes: parsed_adoc.attributes
        )
      end

      ##
      # Returns full HTML code +full_html+ of (index) asciidoc file
      #
      def convert_full_to_html(adoc)
        full_doc = combine_to_single_doc(adoc)
        full_html = full_doc.convert
        return full_html
      end

      ##
      # extract_from_html
      #
      def extract_from_html
        return { id: ref, title: title, body: body}
      end

      ##
      # Generates lunr index .json file from HTML
      #
      def generate_index_json(html)
        ref = []
        title = []
        body = []

        page = ::Nokogiri::HTML(html)
        sections = page.css(SELECTOR_SECTIONS)
        sections.each do |s|
          headings = s.css(SELECTOR_HEADINGS)
          paragraphs = s.css(SELECTOR_PARAGRAPHS)
          headings.each do |h|
            ref << h['id']
            title << h.children.map do |c|
              c.content
            end.join
          end
          paragraphs.each do |p|
            body << p.children.map do |c|
              c.content
            end.join
          end
        end
        # pp ref
        # pp title
        # pp body

        ctx = V8::Context.new
        ctx.load(File.join(__dir__, '..', 'utils', 'lunr.js'))
        ctx.eval(
          'lunr.Index.prototype.dumpIndex = function(){return JSON.stringify(this.toJSON());}'
        )
        lunrjs = ctx.eval('lunr')

        lunr_callback = proc do |this|
          this.ref('id')
          this.field('title')
          this.field('body')

          docs.each do |doc|
            this.add(doc)
          end
        end

        # TODO
        # write this using Nokogiri in Ruby:
        # var documents = HTML2JSON(sectionSelector, sectionContext);

        idx = lunrjs.call(lunr_callback)
        # docs.each do |doc|
        #   idx.add(doc)
        # end

        data = JSON.parse(idx.dumpIndex, max_nesting: false)
        return { index: data, map: map }
      end
    end
  end
end

Toolchain::PreProcessManager.instance.register(Toolchain::Pre::CompileSearchIndex.new)
