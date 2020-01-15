# frozen_string_literal: true

require_relative '../cli.rb'
require_relative '../extension_manager.rb'
require_relative '../utils.rb'
Dir[File.join(__dir__, 'modules.d', '*.rb')].each { |file| require file }

# hash to cache all filename: converted_adoc pairs
ADOC_MAP = Hash.new(nil)
# default index file
DEFAULT_INDEX = 'content/index.adoc'

Entry = Struct.new(:adoc, :output)

# print help
# print all loaded extensions
def print_loaded_extensions
  puts '*** Loaded extensions:'
  Toolchain::ExtensionManager.instance.get.each do |ext|
    puts ext.class.name
  end
end

def print_errors(errors_map)
  errors_map.each do |_file, errors|
    errors.each do |err|
      puts "#{err[:id]}\t#{err[:msg]}".bold.red
    end
  end
end

# load adoc file, convert and return
# https://discuss.asciidoctor.org/Compiling-all-includes-into-a-master-Adoc-file-td2308.html
def load_doc(filename, safe: :safe, parse: false)
  adoc = Asciidoctor.load_file(
    filename,
    catalog_assets: true,
    safe: safe,
    parse: parse
  )
  original = Asciidoctor.load_file(
    filename,
    catalog_assets: true,
    safe: safe,
    parse: parse
  )
  adoc.convert
  return adoc, original
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
    adoc, output = load_doc(filename)
    entry = Entry.new(adoc: adoc, output: output)
    ADOC_MAP[filename] = entry
  else
    entry = ADOC_MAP[filename]
    adoc = entry.adoc
    output = entry.output
  end

  errors = []
  Toolchain::ExtensionManager.instance.get.each do |ext|
    log('EXTENSION', ext.class.name, :cyan)
    errors += ext.run(adoc, output)
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
  args, opt_parser = Toolchain::Test::CLI.parse_args(argv)
  ### Print help
  if args.help
    puts opt_parser
    return 0
  end

  ### Print loaded modules
  print_loaded_extensions if args.debug

  ### Run on file arguments
  if args.file
    stage_log(:test, "Running file checks on file set: #{args.files}")
    stage_log(:test, 'Will exit after this.')
    test_files(args.files) if args.file # will exit if run
  end

  ### Run checks on default files
  index_adoc = args.index_file || DEFAULT_INDEX
  included_files = load_doc(index_adoc)[0].catalog[:includes]
  stage_log(:test, "Running checks on index and included files (total: #{included_files.length + 1})")
  log('INDEX', index_adoc)
  ### CHECK INDEX FIRST
  index_errors = run_tests(index_adoc)
  print_errors(index_adoc => index_errors)
  # if index_errors.empty?
  #   puts 'No errors found in index.adoc!'.bold.green
  #   return 0
  # end

  ### CHECK INCLUDED FILES
  # errors_map = check_docs(included_files, File.join(ENV['PWD'],
  #                                                   File.dirname(index_adoc)))
  errors_map = check_docs(included_files, File.dirname(index_adoc))
  stage_log(:test, 'Printing errors map (filename => errors)')
  print_errors(errors_map)

  # TODO: process errors_map to show which error in index is in which source file
  # post_process_errors(index_errors, errors_map)
  stage_log(:test, 'Test done.')
end
