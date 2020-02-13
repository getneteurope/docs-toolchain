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
    # Adds modules for preprocessing files.
    class CompileSearchIndex < BaseProcess
      SELECTOR_SECTIONS = '#content .sect1, #content .sect2, #content .sect3'
      SELECTOR_HEADINGS = 'h2, h3, h4'
      XPATH_PARAGRAPHS = './div/div/p'
      def initialize; end

      ##
      # Takes adoc Struct +adoc+
      # Returns .json search index for lunr
      def run(html = nil)
        return File.open(html, 'r') do |f|
          generate_index_json(f.read)
        end
      end

      private
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
      def generate_index_json(html_content)
        html = ::Nokogiri::HTML(html_content)
        sections = html.search(SELECTOR_SECTIONS)
        docs = sections.map { |s| _parse_section(s) }

        ctx = V8::Context.new
        ctx.load(File.join(__dir__, '..', 'utils', 'lunr.js'))
        ctx.eval(
          'lunr.Index.prototype.dumpIndex = function() {
               return JSON.stringify(this.toJSON());
           }'
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

        idxjs = lunrjs.call(lunr_callback)

        index = ::JSON.parse(idxjs.dumpIndex, max_nesting: false)
        puts '=== INDEX ==='
        pp index
        return index
      end
    end
  end
end

Toolchain::PostProcessManager.instance.register(Toolchain::Post::CompileSearchIndex.new)
