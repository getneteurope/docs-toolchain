# frozen_string_literal: true

require 'test/unit'
require_relative '../../stages/test/ruby/main_module.rb'
require_relative '../../stages/test/ruby/cli.rb'

# https://stackoverflow.com/a/22777806
def with_captured_stdout
  original_stdout = $stdout  # capture previous value of $stdout
  $stdout = StringIO.new     # assign a string buffer to $stdout
  yield                      # perform the body of the user code
  $stdout.string             # return the contents of the string buffer
ensure
  $stdout = original_stdout  # restore $stdout to its previous value
end

class TestParse < Test::Unit::TestCase
  def test_default
    args = Toolchain::CLI.parse_args([])
    assert_false(args.debug)
    assert_empty(args.files)
    assert_nil(args.index)
  end

  def test_debug
    args = Toolchain::CLI.parse_args(%w[--debug])
    assert_true(args.debug)
    assert_empty(args.files)
    assert_nil(args.index)
  end

  def test_files
    args = Toolchain::CLI.parse_args(%w[--file test.adoc --file content.adoc])
    assert_false(args.debug)
    assert_equal(['test.adoc', 'content.adoc'], args.files)
    assert_nil(args.index)
  end

  def test_index
    args = Toolchain::CLI.parse_args(%w[--index index.adoc])
    assert_false(args.debug)
    assert_empty(args.files)
    assert_equal('index.adoc', args.index)
  end

  def test_index_and_file
    assert_raise(ArgumentError) { Toolchain::CLI.parse_args(%w[--index index.adoc --file file.adoc]) }
  end
end

class TestCLI < Test::Unit::TestCase
  def test_help_cli
    output = with_captured_stdout do
      main(%w[--help])
    end
    assert_true(output.start_with?('Usage:'))
  end
end
