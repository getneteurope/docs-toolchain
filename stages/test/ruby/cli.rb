class CLI
  attr_reader :help, :debug, :file, :files, :index, :index_file

  def initialize(help:, debug:, file:, files:, index:, index_file:)
    @help = help
    @debug = debug
    @file = file
    @files = files
    @index = index
    @index_file = index_file
  end
end

def parse_args(argv=ARGV)
  file_arg = false
  index_arg = false
  args = Hash.new(false)
  args[:files] = []
  args[:index] = nil

  argv.each do |arg|
    if file_arg
      file_arg = false
      args[:files] << arg
      next
    end
    if index_arg
      index_arg = false
      args[:index] << arg
      next
    end

    arg2 = arg.gsub("--", "")
    case arg2
    when "debug", "help"
      args[arg2] = true
    when "file"
      args[arg2] = true
      file_arg = true
    when "index"
      args[arg2] = true
      index_arg = true
    else
      raise "Unknown argument '#{arg}'"
    end
  end

  raise "Cannot provide 'file' and 'index' arguments simultaneously. Pick one!" if args["file"] and args["index"]

  return CLI.new(help: args["help"], debug: args["debug"],
                 file: args["file"], files: args[:files],
                 index: args["index"], index_file: args[:index])
end
