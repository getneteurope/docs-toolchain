# frozen_string_literal: true

require_relative '../cli.rb'
require_relative '../extension_manager.rb'
require_relative '../utils.rb'
Dir[File.join(__dir__, '../', 'extensions.d', '*.rb')].each { |file| require file }

##
# hash to cache all filename: converted_adoc pairs
ADOC_MAP = Hash.new(nil)
##
# default index file
DEFAULT_INDEX = 'content/index.adoc'

##
# represents a pair of parsed, resolved adoc and original adoc
Entry = Struct.new(:adoc, :output)

##
# print help
# print all loaded extensions
def print_loaded_extensions
  puts '*** Loaded extensions:'
  Toolchain::ExtensionManager.instance.get.each do |ext|
    puts ext.class.name
  end
end

##
# print all errors in +errors_map+.
# +errors_map+ is a hash containing a mapping of filename -> [errors].
# format: "id message"
#
# Returns +nil+.
#
def print_errors(errors_map)
  errors_map.each do |_file, errors|
    errors.each do |err|
      puts "#{err[:id]}\t#{err[:msg]}".bold.red
    end
  end
end

##
# Load adoc file +filename+, convert given the parameters +safe+ and +parse+
# https://discuss.asciidoctor.org/Compiling-all-includes-into-a-master-Adoc-file-td2308.html
#
# Returns a pair of converted adoc +adoc+, original adoc +original+
#
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

##
# Test all files given as +files+, +files+ must be a list of filenames.
# Only used for testing individual files, i.e. '--file' parameter.
#
# Returns nothing, this function will exit.
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

##
# Run all extensions registered with +ExtensionManager+ on the file +filename+.
#
# During this process, the file +filename+ will be loaded, converted and cached
# in +ADOC_MAP+.
#
# Returns +errors+ for the given file.
def run_tests(filename)
  if ADOC_MAP.key?(filename)
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

##
# Check all included files in for a given index.
#
# All include files +included_files+ in +content_dir+ will be checked.
# This means each file will be tested with +run_tests+.
#
# Returns a map of +errors_map+ with schema filename => [errors].
def check_docs(included_files, content_dir)
  errors_map = {}
  included_files.map { |f, _| "#{File.join(content_dir, f)}.adoc" }.each do |f|
    log('INCLUDE', "Testing #{f}")
    errors = run_tests(f)
    errors_map[f] = errors
  end
  return errors_map
end

##
# Resolves all errors from index to point to the correct location in include files.
#
# Given +index_errors+ and +errors_map+, determine which errors are false positives and
# which errors are duplicates.
# Remove false positives and merge duplicates (keeping the more specific filename).
#
# Returns +nil+.
def post_process_errors(index_errors, errors_map)
end

##
# Execute the test stage with +argv+ as argument vector.
#
# This stage will pass if there are no errors found.
# Otherwise, the errors are logged and execution of the toolchain ends here,
# as the stage aborts.
#
# Returns +nil+.
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
  files = args.files
  if files
    stage_log(:test, "Running file checks on file set: #{files}")
    stage_log(:test, 'Will exit after this.')
    test_files(files) # will exit if run
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
