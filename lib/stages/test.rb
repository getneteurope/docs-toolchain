# frozen_string_literal: true

require_relative '../cli.rb'
require_relative '../config_manager.rb'
require_relative '../extension_manager.rb'
require_relative '../log/log.rb'
require_relative '../utils/adoc.rb'
require_relative '../utils/paths.rb'

# require extensions
Dir[
  File.join(__dir__, '../', 'extensions.d', '*.rb')
].each { |file| require file }
Dir[
  File.join(::Toolchain.custom_dir, 'extensions.d', '*.rb')
].each { |file| require file }

##
# hash to cache all filename: converted_adoc pairs
ADOC_MAP = Hash.new(nil)
##
# default index file
DEFAULT_INDEX = Toolchain::ConfigManager.instance.get('asciidoc.index.file')
##
# Mutex
MUTEX = Mutex.new

##
# represents a pair of parsed, resolved adoc and original adoc
# Params:
# * +original+: original adoc source code before conversion
# * +parsed+: parsed adoc source code
# * +attributes+: attributes of document
#
Entry = Struct.new(:original, :parsed, :attributes) do
  private

  def original=; end

  def parsed=; end

  def attributes=; end
end

##
# print help
# print all loaded extensions
def print_loaded_extensions
  log('TESTING', 'loaded extensions:')
  Toolchain::ExtensionManager.instance.get.each do |ext|
    log('EXT', ext.class.name)
  end
end

##
# Print all errors in +errors_map+.
# +errors_map+ is a hash containing a mapping of filename -> [errors].
# Format: "id message"
#
# Returns +nil+.
#
def print_errors(errors_map)
  errors_map.each do |file, errors|
    log('ERRORS', "for file #{file}", :red) unless errors.empty?
    errors.each do |err|
      puts "#{err[:id]}\t#{err[:msg]}".bold.red
    end
  end
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
  if ADOC_MAP[filename].nil?

    adoc = Toolchain::Adoc.load_doc(filename,
      'root' => ::Toolchain.document_root
    )
    original = adoc.original
    parsed = adoc.parsed
    attributes = adoc.attributes

    entry = Entry.new(original: original, parsed: parsed, attributes: attributes)
    ADOC_MAP[filename] = entry
  else
    entry = ADOC_MAP[filename]
    parsed = entry.parsed
    original = entry.original
    attributes = entry.attributes
  end

  errors = []
  Toolchain::ExtensionManager.instance.get.each do |ext|
    result = ext.run(adoc)
    errors += result if result.is_a?(Array)
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
  threads = []

  included_files.map { |f, _| "#{File.join(content_dir, f)}.adoc" }.each do |f|
    log('INCLUDE', "Testing #{f}")
    threads << Thread.new do
      errors = run_tests(f)
      MUTEX.synchronize do
        errors_map[f] = errors
      end
    end
  end

  threads.each(&:join)
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
