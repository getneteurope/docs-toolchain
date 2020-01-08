# frozen_string_literal: true

require 'ostruct'

def parse_args(argv = ARGV)
  file_arg = false
  index_arg = false
  args = Hash.new(false)
  'help:debug:file:index'.split(':').each { |arg| args[arg] = false }
  args['files'] = []
  args['index_file'] = nil

  argv.each do |arg|
    if file_arg
      file_arg = false
      args['files'] << arg
      next
    end
    if index_arg
      index_arg = false
      args['index_file'] = arg
      next
    end

    arg2 = arg.gsub('--', '')
    case arg2
    when 'debug', 'help'
      args[arg2] = true
    when 'file'
      args[arg2] = true
      file_arg = true
    when 'index'
      args[arg2] = true
      index_arg = true
    else
      raise "Unknown argument '#{arg}'"
    end
  end

  raise 'Cannot provide "file" and "index" arguments simultaneously. Pick one!' if args['file'] && args['index']

  return OpenStruct.new(args)
end
