# frozen_string_literal: true

require 'ostruct'
require 'optparse'

module Toolchain
  # CLI argument parsing
  module CLI
    def self.parse_args(argv = ARGV)
      args = Hash.new(nil)
      args[:debug] = false
      args[:index] = nil
      args[:files] = []

      OptionParser.new do |parser|
        parser.banner = 'Usage: main.rb [options] [--index INDEX | --file FILE [--file FILE ...]]'

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
          puts parser
          exit
        end.parse!(argv)
      end

      err_msg = 'Cannot provide "file" and "index" arguments simultaneously. Pick one!'
      raise ArgumentError, err_msg if args[:index] && args[:files]

      return OpenStruct.new(args)
    end
  end
end
