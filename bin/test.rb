#!/usr/bin/env ruby
# frozen_string_literal: true

require 'asciidoctor'
require_relative '../lib/stages/test.rb'
require_relative '../lib/utils/adoc.rb'
require_relative '../lib/config_manager'

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

  ### Run checks on default files
  index_adoc = args.index || DEFAULT_INDEX
  log('ARGS', args)
  log('INDEX', index_adoc)

  adoc = Toolchain::Adoc.load_doc(index_adoc,
    'root' => ::Toolchain.document_root
  )
  original = adoc.original
  parsed = adoc.parsed
  attributes = adoc.attributes

  included_files = parsed.catalog[:includes]
  # included_files = Toolchain::Adoc.load_doc(index_adoc)
  stage_log(:test, "Running checks on index and included files (total: #{included_files.length + 1})")
  # log('INCLUDES', 'List of includes:')
  # included_files.each do |k, _|
  #   puts "... #{k}"
  # end
  # log('ATTRIBUTES', '')
  # attributes.each do |k, v|
    # puts "#{k}\t->\t#{v}"
  # end

  # Save all gathered attributes in ConfigManager singleton
  ::Toolchain::ConfigManager.instance.all_attributes(attributes)

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

main unless ENV.key?('SKIP_RAKE_TEST')
