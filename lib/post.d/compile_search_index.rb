# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require_relative '../utils/paths.rb'
require_relative '../utils/adoc.rb'
require_relative '../log/log.rb'
require 'asciidoctor'
require 'nokogiri'
require 'v8'
require 'json'

module Toolchain
  ##
  # Adds modules for postprocessing files.
  module Post
    ##
    # Provides an interface to create a lunr search index
    # from the generated HTML files.
    class CompileSearchIndex < BaseProcess
      SELECTOR_SECTIONS = '#content .sect1, #content .sect2, #content .sect3'
      SELECTOR_HEADINGS = 'h2, h3, h4'
      XPATH_PARAGRAPHS = './div/p'
      def initialize(priority = 0)
        super(priority)
      end

      ##
      # Takes a single HTML file or a list of HTML files (+html+).
      # If not provided, the HTML will be inferred from +$CONTENT_PATH+.
      #
      # +outfile+ is used to write to a specific file for unit tests.
      #
      # Returns JSON search index for lunr
      #
      def run(html = nil, outfile: nil)
        htmls = if html.nil?
                  Dir[File.join(Toolchain.build_path, 'html', '*.html')]
                else
                  (html.is_a?(Array) ? html : [html])
                end
        stage_log(:pre, "Running #{self.class.name} on #{htmls.length} files")
        ConfigManager.instance.get('search.index.exclude').each do |pattern|
          htmls.delete_if do |f|
            !!(File.basename(f) =~ _create_regex(pattern))
          end
        end

        index = generate_index(htmls)
        index_file = ConfigManager.instance.get(
          'search.index.file', default: 'lunrindex.json'
        )
        index_file = File.join(Toolchain.build_path, 'html', index_file)
        index_file = outfile unless outfile.nil?
        File.open(index_file, 'w') do |f|
          f.write(JSON.generate(index))
        end
        return index
      end

      private
      ##
      # Creates a Regex object from a wildcard string +pattern+.
      # https://stackoverflow.com/a/6449534
      #
      # Returns valid Regex.
      #
      def _create_regex(pattern)
        escaped = Regexp.escape(pattern).gsub('\*','.*?')
        return Regexp.new("^#{escaped}$", Regexp::IGNORECASE)
      end


      ##
      # Parse a single HTML file +html_file+.
      # This will convert the document to a Nokogiri object and
      # parse each section.
      # Returns the collective +docs+ list of relevant information
      # to build the lunr index.
      def _parse_html(html_file)
        html = File.open(html_file, 'r') do |f|
          ::Nokogiri::HTML(f.read)
        end

        sections = html.search(SELECTOR_SECTIONS)
        docs = sections.map { |s| _parse_section(s) }
        return docs
      end

      ##
      # Parse a Nokogiri section +sect+ and return relevant information
      # for lunr.
      # Included information is +ref+, the reference or id,
      # +title+, the header of the section and
      # +body+, the text of all p tags below the section div.
      # Returns Hash +{ id, title, body }+
      def _parse_section(sect)
        header = sect.search(SELECTOR_HEADINGS).first
        ps = sect.search(XPATH_PARAGRAPHS)

        ref = header['id']
        title = header.content
        body = ps.map(&:content).join

        return {id: ref, title: title, body: body}
      end

      ##
      # Generates lunr index .json file from HTMLs.
      # +htmls+ is a list of strings, representing the HTML file names.
      # Returns the index JSON for lunr.
      #
      def generate_index(htmls)
        docs = []
        lookup = {}
        htmls.each do |html|
          curr = _parse_html(html)
          curr.each { |e| lookup[e[:id]] = html}
          docs += curr
        end

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

          this.k1(1.3)
          this.b(0)

          docs.each { |doc| this.add(doc) }
        end

        idxjs = lunrjs.call(lunr_callback)

        index = ::JSON.parse(idxjs.dumpIndex, max_nesting: false)
        if ENV.key?('DEBUG')
          puts '=== DATA ==='
          pp index
        end
        return index
      end
    end
  end
end

Toolchain::PostProcessManager.instance.register(Toolchain::Post::CompileSearchIndex.new)
