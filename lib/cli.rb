# frozen_string_literal: true

require 'ostruct'
require 'optparse'

module Toolchain
  ##
  # Build module
  module Build
    ##
    # CLI for Build stage
    module CLI
      ##
      # Parse arguments given as +argv+.
      #
      # Returns hash containing all options as key=value pairs and the parser object.
      def self.parse_args(argv = ARGV)
        args = { content: 'content', index: 'index.adoc', debug: false, help: false }

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

  ##
  # Test module
  module Test
    # CLI for Test stage
    module CLI
      ##
      # Parse arguments given as +argv+.
      #
      # Returns hash containing all options as key=value pairs and the parser object.
      def self.parse_args(argv = ARGV)
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
  ##
  # Pre- and Post-processing module
  module Process
    # CLI for Pre- and Post-processing stages
    module CLI
      ##
      # Parse arguments given as +argv+.
      #
      # Returns hash containing all options as key=value pairs and the parser object.
      def self.parse_args(argv = ARGV)
        args = { help: false, debug: false, list: false, run: false }

        opt_parser = OptionParser.new do |parser|
          parser.banner = 'Usage: main.rb [--help | --debug | --list | --run]'

          parser.on('-d', '--debug', 'enable debug mode') do
            args[:debug] = true
          end

          parser.on('-l', '--list', 'list all processing units that will be loaded') do
            args[:list] = true
          end

          parser.on('-h', '--help', 'print this help') do
            args[:help] = true
          end
        end
        opt_parser.parse!(argv)

        return OpenStruct.new(args), opt_parser
      end
    end
    # END CLI
  end
  # END Processing
end
# END TOOLCHAIN
