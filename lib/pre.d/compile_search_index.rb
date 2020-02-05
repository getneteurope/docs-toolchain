# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require 'v8'
require 'nokogiri'

module Toolchain
  module Pre
    ##
    # Adds modules for preprocessing files.
    class CompileSearchIndex < BaseProcess
      def initialize; end

      ##
      # Takes adoc Struct +adoc+
      # Returns .json search index for lunr
      def run(adoc)
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
      # extract_from_html
      #
      def extract_from_html
        return { id: ref, title: title, body: body}
      end

      ##
      # Generates lunr index .json file from HTML
      #
      def generate_index_json(html)
        dom = Nokogiri::HTML(html)

        js_context = V8::Context.new
        js_context.load(File.join(__dir__, '../', 'utils', 'lunr.js'))
        js_context.eval('lunr.Index.prototype.dumpIndex = function(){return JSON.stringify(this.toJSON());}')
        ref = js_context.eval('lunr')
  
        fields = %w[title body]
        lunr_conf = proc do |this|
          this.ref('id')
          fields.each do |name|
            this.field(name) #, {:boost => boost})
          end
        end
  
        # function htmlElementsToJSON(listSelector, unmarshalFunction) {
        #   // add the list elements to lunr
        #   var qs = $(listSelector, "#content .sect2, #content .sect3");
        #   var entries = [];
        #   for (var i = 0; i < qs.length; i++) {
        #     var $q = $(qs[i]);
        #     entries.push(unmarshalFunction($q));
        #   }
        #   return entries;
        # }
        # var documents = htmlElementsToJSON(listSelector, function($element) {
        #   var ref = $element.find("h2, h3, h4").attr('id');
        #   var title = $element.find("h2, h3, h4").text();
        #   var body = $element.find("p").text();
        #   return { id: ref, title: title, body: body };
        # });

        docs = 

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
