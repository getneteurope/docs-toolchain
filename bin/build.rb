#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/cli.rb'
require_relative '../lib/stages/build.rb'

def main(argv = ARGV)
  args, opt_parser = Toolchain::Build::CLI.parse_args(argv)
  if args.help
    puts opt_parser
    exit 0
  end

  stage_log(:build, 'Starting build stage')
  stage_log(:build, "running build with index: #{args.index}")
  Toolchain::Build.build(index: args.index)
  stage_log(:build, 'Build done')
end

main
