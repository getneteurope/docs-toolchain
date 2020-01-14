#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative './cli.rb'
require_relative './build.rb'
require_relative '../../utils/ruby_utils.rb'

def main(argv = ARGV)
  args, opt_parser = Toolchain::Build::CLI.parse_args(argv)
  if args.help
    puts opt_parser
    exit 0
  end

  stage_log(:build, 'Starting build stage')
  stage_log(:build, "running build setup on content folder: #{args.content}")
  Toolchain::Build.setup(content: args.content)
  stage_log(:build, "running build with index: #{args.index}")
  Toolchain::Build.build(index: args.index)
  stage_log(:build, 'Build done')
end

main
