# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require 'v8'

module Toolchain
  module Pre
    ##
    # Adds modules for preprocessing files.
    class CompileSearchIndex < BaseProcess
      def initialize
      end

      ##
      # 
      def run(adoc)
       pp full_html(adoc)
      end

      private

      ##
      # Returns full HTML code +html+ of (index) asciidoc file
      #
      def full_html(adoc)
        original = adoc.original
        parsed = adoc.parsed
        attributes = adoc.attributes
  
        errors = []
        # TODO: research why read_lines can be empty
        lines = parsed.reader.read_lines
        lines = parsed.reader.source_lines if lines.empty?
  
        reader = Asciidoctor::PreprocessorReader.new parsed, lines
        combined_source = reader.read_lines

        pp combined_source

        doc = Asciidoctor::Document.new combined_source, safe: :unsafe, attributes: attributes
        html = doc.convert
        return html
      end

      ##
      # Generates lunr index .json file from HTML
      #
      def generate_index_json(html)
        js_context = V8::Context.new
        js_context.load('/tmp/lunr.js')
        js_context.eval('lunr.Index.prototype.dumpIndex = function(){return JSON.stringify(this.toJSON());}')
        ref = js_context.eval('lunr')
  
        lunr_conf = proc do |this|
          this.ref('id')
          fields.each do |name|
            this.field(name) #, {:boost => boost})
          end
        end
  
        idx = ref.call(lunr_conf)
  
        docs.each do |doc|
          idx.add(doc)
        end
  
        data = JSON.parse(idx.dumpIndex(), max_nesting: false)
  
        { index: data, map: map }
      end
    end
  end
end

Toolchain::PreProcessManager.instance.register(Toolchain::Pre::CompileSearchIndex.new)
