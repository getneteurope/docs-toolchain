# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require 'v8'

module Toolchain
  module Pre
    ##
    # Adds modules for preprocessing files.
    class CompileSearchIndex < BaseProcess
      attr_reader :full_html #unused
      attr_reader :full_doc

      def initialize; end

      ##
      # 
      def run(adoc)
       @full_html = convert_full_to_html(adoc)
       pp @full_html
      end

      private

      ##
      # Returns Asciidoctor::Document +full_doc+ with all includes included.
      #
      def combine_to_single_doc(adoc)
        parsed_adoc = adoc.parsed
        lines = parsed_adoc.reader.source_lines
        reader = Asciidoctor::PreprocessorReader.new parsed_adoc, lines
        combined_source = reader.read_lines
        return Asciidoctor::Document.new combined_source, safe: :unsafe, attributes: adoc.attributes
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
      # Generates lunr index .json file from HTML
      #
      def generate_index_json(html)
        js_context = V8::Context.new
        js_context.load('../utils/lunr.js')
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
