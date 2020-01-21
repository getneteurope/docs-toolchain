# frozen_string_literal: true

require_relative '../cli.rb'
require_relative '../extension_manager.rb'
require_relative '../utils.rb'
Dir[File.join(__dir__, '../', 'extensions.d', '*.rb')].each { |file| require file }

# hash to cache all filename: converted_adoc pairs
ADOC_MAP = Hash.new(nil)
# default index file
DEFAULT_INDEX = 'content/index.adoc'

#Attributes = Hash.new(nil)
Entry = Struct.new(:original, :converted)

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

def get_modified_attributes(original, attribs={})
  original.reader.read_lines.grep(/^:.+:/).each { |line|
  # TODO use asciidoctor to do this for attributes in attributes
    k, v = line.match(/^:(.+): ?(.*)/).captures
    attribs[k] = v
  }
  attribs
end

# load adoc file, convert and return
# https://discuss.asciidoctor.org/Compiling-all-includes-into-a-master-Adoc-file-td2308.html
def load_doc(filename, attribs={})
  original = Asciidoctor.load_file(
    filename,
    catalog_assets: true,
    sourcemap: true,
    safe: :unsafe,
    parse: false,
    attributes: attribs
  )
  attributes = get_modified_attributes original, attribs
  converted = Asciidoctor.load_file(
    filename,
    catalog_assets: true,
    sourcemap: true,
    safe: :unsafe,
    parse: false,
    attributes: attributes
  )
  # converted = Marshal.load(Marshal.dump(original)) # deep copy. I don't trust it
  converted.convert
  adoc = OpenStruct.new(
    original: original,
    converted: converted,
    attributes: attributes
  )
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

    adoc = load_doc filename
    original = adoc.original
    converted = adoc.converted
    attributes = adoc.attributes

    entry = Entry.new(original: original, converted: converted, attributes: attributes)
    ADOC_MAP[filename] = entry
  else
    entry = ADOC_MAP[filename]
    converted = entry.converted
    original = entry.original
    attributes = entry.attributes
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
def post_process_errors(index_errors, errors_map); end

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
  index_adoc = args.index || DEFAULT_INDEX
  log('ARGS', args)
  log('INDEX', index_adoc)

  ############# adoc, original = load_doc(index_adoc)
  # included_files = adoc.catalog[:includes]
  adoc = load_doc index_adoc
  original = adoc.original
  converted = adoc.converted
  attributes = adoc.attributes

  included_files = converted.catalog[:includes]
  #included_files = load_doc(index_adoc)
  stage_log(:test, "Running checks on index and included files (total: #{included_files.length + 1})")
  log('INCLUDES', included_files)
  log('ATTRIBUTES2', attributes)

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
