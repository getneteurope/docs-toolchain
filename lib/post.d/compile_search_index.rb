# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require_relative '../utils/paths.rb'
require_relative '../utils/adoc.rb'
require_relative '../utils/hash.rb'
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
        @toc_file = File.join(::Toolchain.build_path, CM.get('toc.json_file'))
        @nodes = {}
        @paragraph_max_length = 140
      end

      ##
      # Takes a single HTML file or a list of HTML files (+html+).
      # If not provided, the HTML will be inferred from +$CONTENT_PATH+.
      #
      # +outfile+ is used to write to a specific file for unit tests.
      #
      # Returns JSON search index for lunr
      #
      def run(html = nil, outfile: nil, dbfile: nil)
        htmls = if html.nil?
                  Dir[File.join(Toolchain.build_path, 'html', '*.html')]
                else
                  (html.is_a?(Array) ? html : [html])
                end

        stage_log(:post, "Running #{self.class.name} on #{htmls.length} files")
        stage_log(:post, "Parse #{@toc_file} as Table of Content")
        toc_orig = ::JSON.parse(File.read(@toc_file))

        # build toc entry tree
        def add_to_toc(entry)
          return if entry.nil? || entry.size.zero?
          @nodes[entry['id']] = entry.only(%w[parents label]) unless entry['level'] == -1
          entry['children'].each do |e|
            add_to_toc(e)
          end
        end
        add_to_toc(toc_orig)

        # exclude certain files, defined in the yaml config
        ConfigManager.instance.get('search.exclude').each do |pattern|
          htmls.delete_if do |f|
            !!(File.basename(f) =~ _create_regex(pattern))
          end
        end

        ###
        # generate index and lookup and write to file
        index, lookup = generate_index(htmls)

        index_file = ConfigManager.instance.get(
          'search.index.file', default: 'lunrindex.json'
        )
        db_file = ConfigManager.instance.get(
          'search.db.file', default: 'lunrdb.json'
        )

        index_file = File.join(Toolchain.build_path, 'html', index_file)
        db_file = File.join(Toolchain.build_path, 'html', db_file)

        index_file = outfile unless outfile.nil?
        db_file = dbfile unless dbfile.nil?

        File.open(index_file, 'w') do |f|
          f.write(JSON.generate(index))
        end
        File.open(db_file, 'w') do |f|
          f.write(JSON.generate(lookup))
        end

        return index, lookup
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
      # Get the parents sections of a section given the section id +id+.
      # Returns a descending array of parent sections,
      # starting with the highest level.
      def _get_parent_sections(id)
        entry = @nodes[id]
        return nil if entry.nil?
        return entry['parents']
      end

      ##
      # Get the label for this section given the section id +id+.
      # Returns the label, if there is one, +nil+ otherwise.
      def _get_label(id)
        entry = @nodes[id]
        return nil if entry.nil?
        return entry['label']
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
        docs = sections.map { |s| _parse_section(s, html_file) }
        return docs
      end

      ##
      # Parse a Nokogiri section +sect+ and return relevant information
      # for lunr.
      # This function needs the +filename+ in order to create valid links
      # later on, when the lunr search is implemented.
      # Included information is +ref+, the reference or id,
      # +title+, the header of the section and
      # +body+, the text of all p tags below the section div.
      # Returns Hash +{ id, title, body }+
      def _parse_section(sect, filename)
        header = sect.search(SELECTOR_HEADINGS).first
        ps = sect.search(XPATH_PARAGRAPHS)

        ref = header['id']
        title = header.content
        body = ps.map(&:content).join.gsub(/\R+/, ' ') # sub newline for space
        file = File.basename(filename)

        parents = _get_parent_sections(ref)
        label = _get_label(ref)

        # format body
        if body.size > @paragraph_max_length
          last_idx = body.index(' ', @paragraph_max_length)
          # only format if there is a whitespace after the specified length
          unless last_idx.nil?
            tmp_body = body[0..last_idx]
            body = tmp_body.concat(tmp_body[-1] == '.' ? '..' : '...')
          end
        end

        return {
          id: ref,
          title: title.delete("\n"),
          parents: parents,
          label: label,
          body: body,
          file: file
        }
      end

      ##
      # Generates lunr index JSON and lunr DB JSON file from HTMLs.
      # +htmls+ is a list of strings, representing the HTML file names.
      # Returns the index JSON and DB JSON for lunr.
      #
      def generate_index(htmls)
        docs = []
        lookup = {}
        htmls.each do |html|
          curr = _parse_html(html)
          curr.each { |e| lookup[e[:id]] = e.reject { |k,_| k == :id } }
          docs += curr
        end

        ctx = V8::Context.new
        ctx.load(File.join(__dir__, '..', 'utils', 'lunr.js'))
        ctx.eval(
          '
            lunr.Index.prototype.dumpIndex = function() {
              return JSON.stringify(this.toJSON());
            }'
        )

        lunrjs = ctx.eval('lunr')
        lunr_callback = proc do |this|
          this.ref('id')
          this.field('title')
          this.field('body')
          this.field('file')

          this.k1(1.3)
          this.b(0)

          docs.each { |doc| this.add(doc) }
        end

        idxjs = lunrjs.call(lunr_callback)

        index = ::JSON.parse(idxjs.dumpIndex, max_nesting: false)
        return index, lookup
      end

    end
  end
end

Toolchain::PostProcessManager.instance.register(Toolchain::Post::CompileSearchIndex.new)
