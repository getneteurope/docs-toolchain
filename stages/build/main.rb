#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative './cli.rb'
require_relative './build.rb'

def main(argv = ARGV)
  args, opt_parser = Toolchain::Build::CLI.parse_args(argv)
  if args.help
    puts opt_parser
    exit 0
  end

  Toolchain::Build.setup(content: args.content)
  Toolchain::Build.build(index: args.index)
end

main
