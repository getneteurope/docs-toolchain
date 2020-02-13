# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require_relative '../utils/paths.rb'
require_relative '../utils/adoc.rb'
require 'asciidoctor'
require 'nokogiri'
require 'v8'
require 'json'

module Toolchain
  module Post
    ##
    # Adds modules for postprocessing files.
    class CompileSearchIndex < BaseProcess
      SELECTOR_SECTIONS = '#content .sect1, #content .sect2, #content .sect3'
      SELECTOR_HEADINGS = 'h2, h3, h4'
      XPATH_PARAGRAPHS = './div/div/p'
      def initialize; end

      ##
      # Takes a single HTML file or a list of HTML files (+html+).
      # If not provided, the HTML will be inferred from +$CONTENT_PATH+.
      #
      # Returns JSON search index for lunr
      #
      def run(html = nil)
        htmls = (html.is_a?(Array) ? html : [html])

        index = generate_index_json(htmls)
        # TODO write index to file
      end

      private
      def _parse_html(html_file)
        html = File.open(html_file, 'r') do |f|
          ::Nokogiri::HTML(f.read)
        end
        sections = html.search(SELECTOR_SECTIONS)
        docs = sections.map { |s| _parse_section(s) }
        puts docs.inspect
        return docs
      end

      def _parse_section(sect)
        header = sect.search(SELECTOR_HEADINGS).first
        ps = sect.search(XPATH_PARAGRAPHS)

        ref = header['id']
        title = header.content
        body = ps.map(&:content).join

        return {id: ref, title: title, body: body}
      end

      ##
      # Generates lunr index .json file from HTML
      #
      def generate_index_json(htmls)
        docs = []
        htmls.each { |html| docs += _parse_html(html) }
        puts '=== DOCS ==='
        puts docs

        ctx = V8::Context.new
        ctx.load(File.join(__dir__, '..', 'utils', 'lunr.js'))
        ctx.eval(
          'lunr.Index.prototype.dumpIndex = function() {
               return JSON.stringify(this.toJSON());
           }'
        )

        puts '///  JS  ///'
        lunrjs = ctx.eval('lunr')
        lunr_callback = proc do |this|
          this.ref('id')
          this.field('title')
          this.field('body')

          this.k1(1.3)
          this.b(0)

          docs.each { |doc| this.add(doc) }
        end

        idxjs = lunrjs.call(lunr_callback)

        index = ::JSON.parse(idxjs.dumpIndex, max_nesting: false)
        puts '=== DATA ==='
        pp index
        return index
      end
    end
  end
end

Toolchain::PostProcessManager.instance.register(Toolchain::Post::CompileSearchIndex.new)
