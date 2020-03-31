#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/cli.rb'
require_relative '../lib/process_manager.rb'
require_relative '../lib/log/log.rb'
Dir[File.join(__dir__, '../', 'lib', 'post.d', '*.rb')].each { |file| require file }

def main(argv = ARGV)
  args, opt_parser = Toolchain::Process::CLI.parse_args(argv)
  if args.help
    puts opt_parser
    exit 0
  end

  if args.list || args.debug
    log('POST-PROCESSING', 'loaded processes:')
    Toolchain::PostProcessManager.instance.get.each do |proc|
      log('PROC', proc.class.name)
    end
    exit 0 if args.list
  end

  stage_log(:post, 'Starting post-processing stage')
  ret = Toolchain::PostProcessManager.instance.run
  exit ret
end

main
