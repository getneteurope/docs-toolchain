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
# Params:
# * +adoc+:     converted adoc document
# * +original+: original adoc source code before conversion
#
Entry = Struct.new(:adoc, :original) do
  private

  def adoc=; end

  def original=; end
end

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
    adoc, original = load_doc(filename)
    entry = Entry.new(adoc: adoc, original: original)
    ADOC_MAP[filename] = entry
  else
    entry = ADOC_MAP[filename]
    adoc = entry.adoc
    original = entry.original
  end

  errors = []
  Toolchain::ExtensionManager.instance.get.each do |ext|
    log('EXTENSION', ext.class.name, :cyan)
    errors += ext.run(adoc, original)
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

