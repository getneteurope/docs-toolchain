class CLI
  attr_reader :help, :debug, :file, :files

  def initialize(help:, debug:, file:, files:)
    @help = help
    @debug = debug
    @file = file
    @files = files
  end
end

def parse_args
  file_arg = false
  args = Hash.new(false)
  args[:files] = []

  ARGV.each do |arg|
    if file_arg == true
      file_arg = false
      args[:files] << arg
      next
    end

    arg2 = arg.gsub("--", "")
    case arg2
    when "debug", "help"
      args[arg2] = true
    when "file"
      args[arg2] = true
      file_arg = true
    else
      raise "Unknown argument '#{arg}'"
    end
  end

  return CLI.new(help: args["help"], debug: args["debug"], file: args["file"], files: args[:files])
end
