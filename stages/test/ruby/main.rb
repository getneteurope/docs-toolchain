#!/usr/bin/env ruby

require "asciidoctor"
require_relative "./cli.rb"
require_relative "./extension_manager.rb"
Dir[File.join(__dir__, "modules.d", "*.rb")].each { |file| require file }

ADOC_MAP = Hash.new(nil)

def run_tests(filename)
  if ADOC_MAP[filename].nil?
    adoc = Asciidoctor.load_file(filename, catalog_assets: true)
    adoc.convert
    ADOC_MAP[filename] = adoc
  else
    adoc = ADOC_MAP[filename]
  end

  errors = []
  Toolchain::ExtensionManager.instance.get.each do |ext|
    errors += ext.run(adoc)
  end
  return errors
end

def main
  args = parse_args
  ### Print help
  if args.help
    puts "Usage: #{__FILE__} [--help] [--debug] [--file FILE] ..."
    return 0
  end

  ### Print loaded modules
  if args.debug
    puts "*** Loaded extensions:"
    Toolchain::ExtensionManager.instance.get.each do |ext|
      puts ext.class.name
    end
  end

  ### Run on file arguments
  if args.file
    args.files.each do |f|
      errors = run_tests(f)
      puts f
      puts errors
    end
    return 0
  end

  ### Run checks on default files
  index_adoc = "index.adoc"
  ### CHECK INDEX FIRST
  index_errors = run_tests(index_adoc)
  if index_errors.empty?
    puts "No errors found in index.adoc!"
    return 0
  end

  errors_map = { index_adoc => index_errors }
  adoc_files = Dir.glob("**/*.adoc")
  adoc_files.each do |f|
    errors = run_tests(f)
    errors_map[f] = errors
  end

  puts errors_map
  # TODO: process errors_map to show which error in index is in which source file
end

main
