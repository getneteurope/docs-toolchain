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
  puts '*** Loaded extensions:'
  Toolchain::ExtensionManager.instance.get.each do |ext|
    puts ext.class.name
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
  errors_map.each do |_file, errors|
    errors.each do |err|
      puts "#{err[:id]}\t#{err[:msg]}".bold.red
    end
  end
end

##
# Takes document +doc+.
# Returns +attribs+ all attributes newly set in this document.
#
def get_mod_attrs_from_doc(doc)
  attribs = {}
  doc.convert
  attrs_mod = doc.instance_variable_get :@attributes_modified
  attrs_mod.each do |k, _v|
    attribs[k] = doc.attributes[k]
  end
  attribs
end

##
# Recursively loops thourgh asdciidoc includes and collects their newly set attributes.
# Returns collection of attributes +attribs+.
def collect_attributes(doc, attribs = {})
  # get initial attribs set in index
  attribs = get_mod_attrs_from_doc(doc) if attribs == {}
  incs = doc.catalog[:includes].keys.to_set
  return attribs if incs.empty?

  incs.each do |inc|
    inc_file_path = doc.normalize_asset_path(inc + '.adoc')
    doc = Asciidoctor.load_file(
      inc_file_path,
      catalog_assets: true,
      sourcemap: true,
      safe: :unsafe,
      parse: false,
      attributes: attribs
    )
    # combine new modified attr from current file with existing attribs
    get_mod_attrs_from_doc(doc).each do |k, v|
      attribs[k] = v
    end
    collect_attributes(doc, attribs)
  end
  attribs
end

##
# Load adoc file +filename+, convert given the parameters +safe+ and +parse+
# https://discuss.asciidoctor.org/Compiling-all-includes-into-a-master-Adoc-file-td2308.html
#
# Returns a pair of converted adoc +adoc+, original adoc +original+
#
def load_doc(filename, attribs = {})
  original = Asciidoctor.load_file(
    filename,
    catalog_assets: true,
    sourcemap: true,
    safe: :unsafe,
    parse: false,
    attributes: attribs
  )
  parsed = Asciidoctor.load_file(
    filename,
    catalog_assets: true,
    sourcemap: true,
    safe: :unsafe,
    parse: true,
    attributes: attribs
  )
  attributes = collect_attributes parsed, attribs

  adoc = OpenStruct.new(
    original: original,
    parsed: parsed,
    attributes: attributes
  )
  return adoc
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

    adoc = load_doc filename
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
    log('EXTENSION', ext.class.name, :cyan)
    errors += ext.run(adoc)
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
