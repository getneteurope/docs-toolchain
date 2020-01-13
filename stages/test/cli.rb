# frozen_string_literal: true

require 'ostruct'
require 'optparse'

module Toolchain
  module Test
    # CLI argument parsing
    module CLI
      def self.parse_args(argv = ARGV)
        # parses argv (default: argv=ARGV) and returns the arguments as ostruct and the parser object
        # return: OpenSruct(args), parser
        #
        args = { help: false, debug: false, index: nil, files: [] }

        opt_parser = OptionParser.new do |parser|
          parser.banner = 'Usage: main.rb [options] [--index INDEX | --file FILE [--file FILE ...]]
        Default: index file is \'content/index.adoc\''

          parser.on('-d', '--debug', 'enable debug mode') do
            args[:debug] = true
          end

          parser.on('-iINDEX', '--index INDEX', 'specify an index file') do |index|
            args[:index] = index
          end
          parser.on('-fFILE', '--file FILE', 'specify multiple files instead of one index file') do |file|
            args[:files] << file
          end

          parser.on('-h', '--help', 'print this help') do
            args[:help] = true
          end
        end
        opt_parser.parse!(argv)

        err_msg = 'Cannot provide "file" and "index" arguments simultaneously. Pick one!'
        raise ArgumentError, err_msg if args[:index] && !args[:files].empty?

        return OpenStruct.new(args), opt_parser
      end
    end
    # END CLI
  end
  # END TEST
end
# END TOOLCHAIN
