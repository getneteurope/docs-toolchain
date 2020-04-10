# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require 'nokogiri'
# toolchain
require 'errors'

module Toolchain
  module Pre
    ##
    # Adds modules for preprocessing files.
    class CombineJS < BaseProcess
      def initialize(priority)
        super(priority)
        @header_default = 'docinfo.html'
        @footer_default = 'docinfo-footer.html'
      end

      ##
      # Combines JS files referenced in docinfo{,-footer}.html
      # into a single .js file and then reinserts the combined
      # file as script tags into the HTML files.
      #
      # Returns nothing.
      #
      def run
        root = ::Toolchain.build_path
        header_path = File.join(root, @header_default)
        footer_path = File.join(root, @footer_default)
        htmls = [header_path, footer_path]

        htmls.each do |path|
          stage_log('pre', "[CombineJS] -> #{path}")
          begin
            unless File.file?(path)
              raise(::Toolchain::FileNotFound,
                "Could not find html file #{path}")
            end

            html = Nokogiri::HTML.fragment(File.read(path))
            combine_and_replace(html, path)
          rescue StandardError => e
            log('ERROR', 'CombineJS', :red)
            log('ERROR', e.message, :red)
            raise e
          end
        end
      end

      ##
      # Replaces all JS tags in an Nokogiri HTML object +html+ with
      # one tag that includes one big blob JS.
      #
      # Overwrites the initial file at +path+.
      #
      # Returns nothing.
      #
      def combine_and_replace(html, path)
        # returns nil if no tags were removed, e.g. nothing
        # can be combined
        html = combine_js(html, path)
        return if html.nil? || html.to_s.empty?

        # remove empty lines
        idx = html.children.find_index do |c|
          !c.to_s.strip.empty? # find first non-empty element
        end
        html.children.slice(0, idx).map(&:remove)

        # replace original HTML
        File.open(path, 'w') do |file|
          file.puts(html.to_html)
        end
      end

      ##
      # Combines JS files found in +html+ Nokogiri object,
      # and writes the combined JS to a new file.
      # Takes HTML file +path+ and +separator+.
      #
      # Returns blob file path +blob_path+ or +nil+ if no
      # JS tags were found (i.e. nothing was combined).
      #
      def combine_js(html, path, separator = "\n\n")
        dir = File.dirname(path)
        src_files = get_script_sources(html).map do |src|
          File.join(dir, src)
        end
        return nil if src_files.empty?

        blob = src_files.map do |js|
          File.read(js)
        end.join(separator)

        root = File.dirname(src_files.first)
        blob_file =
          "blob_#{path.include?('footer') ? 'footer' : 'header'}.js"
        js_blob_relpath = File.join('js', blob_file)
        js_blob_path = File.join(root, blob_file)

        File.open(js_blob_path, 'w+') do |blobfile|
          blobfile.puts(blob)
        end
        html.add_child(%(<script src="#{js_blob_relpath}"></script>))

        return html
      end

      ##
      # Take Nokogiri HTML +html+ and check for javascript files.
      #
      # Returns +js_files+ array containing +src+ attribute
      # values of script.
      #
      #   e.g. <script src="js/1.js"> --> ['js/1.js']
      def get_script_sources(html)
        delete_list = []
        js_files = html.search('script').map do |tag|
          next if tag.key?('noblob')
          next unless tag.key?('src')
          next unless tag.children.empty?
          next if tag.attribute('src').value.start_with?('js/vendor')

          delete_list << tag
          tag.attribute('src').value
        end

        delete_list.each(&:remove)
        return js_files.compact # remove nil
      end
    end
  end
end

unless %w[FAST SKIP_JS SKIP_COMBINE].any? { |var| ENV.key?(var) }
  # must have higher priority than TranspileJS
  Toolchain::PreProcessManager.instance.register(
    Toolchain::Pre::CombineJS.new(100))
end
