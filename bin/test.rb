#!/usr/bin/env ruby
# frozen_string_literal: true

require 'asciidoctor'
require_relative '../lib/stages/test.rb'

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
  unless files.empty?
    stage_log(:test, "Running file checks on file set: #{files}")
    stage_log(:test, 'Will exit after this.')
    test_files(files) # will exit if run
  end

  ### Run checks on default files
  index_adoc = args.index || DEFAULT_INDEX
  log('ARGS', args)
  log('INDEX', index_adoc)

  ############# adoc, original = load_doc(index_adoc)
  # included_files = adoc.catalog[:includes]
  adoc = load_doc index_adoc
  original = adoc.original
  parsed = adoc.parsed
  attributes = adoc.attributes

  included_files = parsed.catalog[:includes]
  # included_files = load_doc(index_adoc)
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

main
