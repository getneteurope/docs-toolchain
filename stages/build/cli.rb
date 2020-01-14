# frozen_string_literal: true

require 'optparse'
require 'ostruct'

module Toolchain
  module Build
    module CLI
      def self.parse_args(argv = ARGV)
        args = { content: 'content', index: 'index.adoc',
          debug: false, help: false }

        # TODO: add options for custom build dir
        # TODO: add support for debug flag
        opt_parser = OptionParser.new do |parser|
          parser.banner = "Usage: main.rb [options] [--content CONTENT] [--index INDEX]
Defaults:
  - content: 'content/'
  - index:   'index.adoc'"

          parser.on('--debug', 'enable debug mode') do
            args[:debug] = true
          end

          parser.on('-c CONTENT', '--content CONTENT', 'content directory') do |content|
            args[:content] = content
          end

          parser.on('-i INDEX', '--index INDEX', 'index file within the content directory') do |index|
            args[:index] = index
          end

          parser.on('-h', '--help', 'print this message') do
            args[:help] = true
          end
        end.parse!(argv)
        return OpenStruct.new(args), opt_parser
      end
    end
    # END CLI
  end
  # END BUILD
end
# END TOOLCHAIN
