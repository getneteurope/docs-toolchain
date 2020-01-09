# frozen_string_literal: true

require_relative './cli.rb'
require_relative './extension_manager.rb'
require_relative '../../../utils/ruby_utils.rb'
Dir[File.join(__dir__, 'modules.d', '*.rb')].each { |file| require file }

# hash to cache all filename: converted_adoc pairs
ADOC_MAP = Hash.new(nil)
# default index file
DEFAULT_INDEX = 'content/index.adoc'

# print help
def print_help
  puts 'Usage: ./script [--help] [--debug] [--index INDEX] [--file FILE] ...'
  puts
  puts 'Provide either:'
  puts '        INDEX    a single index file, automatically following the'
  puts '                 include statements to find errors'
  puts '        FILE     one or multiple files, includes will not be followed'
  puts '        NOTHING  same as INDEX with INDEX=index.adoc'
end

# print all loaded extensions
def print_loaded_extensions
  puts '*** Loaded extensions:'
  Toolchain::ExtensionManager.instance.get.each do |ext|
    puts ext.class.name
  end
end

# load adoc file, convert and return
def load_doc(filename, safe: :safe, parse: false)
  adoc = Asciidoctor.load_file(filename,
                               catalog_assets: true,
                               safe: safe,
                               parse: parse)
  adoc.convert
  return adoc
end

# test all files given as parameter
# only used for testing individual files, i.e. '--file' parameter
def test_files(files)
  files.each do |f|
    errors = run_tests(f)
    next if errors.empty?

    puts f.blue.bold
    errors.each do |err|
      puts "#{err[:id]}\t#{err[:msg]}".bold.red
    end
  end
  exit 0
end

# run all extensions on the filename
def run_tests(filename)
  if ADOC_MAP[filename].nil?
    adoc = load_doc(filename)
    ADOC_MAP[filename] = adoc
  else
    adoc = ADOC_MAP[filename]
  end

  errors = []
  Toolchain::ExtensionManager.instance.get.each do |ext|
    log('EXTENSION', ext.class.name, :cyan)
    errors += ext.run(adoc)
  end
  return errors
end

# check all included files for a given index
def check_docs(included_files, content_dir)
  errors_map = {}
  included_files.map { |f, _| "#{File.join(content_dir, f)}.adoc" }.each do |f|
    log('INCLUDE', "Testing #{f}")
    errors = run_tests(f)
    errors_map[f] = errors
  end
  return errors_map
end

# resolves all errors from index to point to the correct location in include files
def post_process_errors(index_errors, errors_map)
end

def main(argv = ARGV)
  args = Toolchain::CLI.parse_args(argv)
  ### Print help
  if args.help
    print_help
    return 0
  end

  ### Print loaded modules
  print_loaded_extensions if args.debug

  ### Run on file arguments
  test_files(args.files) if args.file # will exit if run

  ### Run checks on default files
  index_adoc = (args.index || DEFAULT_INDEX)
  log('INDEX', index_adoc)
  included_files = load_doc(index_adoc).catalog[:includes]
  ### CHECK INDEX FIRST
  index_errors = run_tests(index_adoc)
  # if index_errors.empty?
  #   puts 'No errors found in index.adoc!'.bold.green
  #   return 0
  # end

  ### CHECK INCLUDED FILES
  # errors_map = check_docs(included_files, File.join(ENV['PWD'],
  #                                                   File.dirname(index_adoc)))
  errors_map = check_docs(included_files, File.dirname(index_adoc))
  puts errors_map

  # TODO: process errors_map to show which error in index is in which source file
  # post_process_errors(index_errors, errors_map)
end
