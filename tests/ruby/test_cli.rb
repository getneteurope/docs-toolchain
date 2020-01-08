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
    args = parse_args([])
    assert_false(args.help)
    assert_false(args.debug)
    assert_false(args.file)
    assert_empty(args.files)
    assert_false(args.index)
    assert_nil(args.index_file)
  end

  def test_help
    args = parse_args(['--help'])
    assert_true(args.help)
    assert_false(args.debug)
    assert_false(args.file)
    assert_empty(args.files)
    assert_false(args.index)
    assert_nil(args.index_file)
  end

  def test_debug
    args = parse_args(['--debug'])
    assert_false(args.help)
    assert_true(args.debug)
    assert_false(args.file)
    assert_empty(args.files)
    assert_false(args.index)
    assert_nil(args.index_file)
  end

  def test_files
    args = parse_args(['--file', 'test.adoc', '--file', 'content.adoc'])
    assert_false(args.help)
    assert_false(args.debug)
    assert_true(args.file)
    assert_equal(args.files, ['test.adoc', 'content.adoc'])
    assert_false(args.index)
    assert_nil(args.index_file)
  end
  def test_index
    args = parse_args(['--index', 'index.adoc'])
    assert_false(args.help)
    assert_false(args.debug)
    assert_false(args.file)
    assert_empty(args.files)
    assert_true(args.index)
    assert_equal(args.index_file, 'index.adoc')
  end
end

class TestCLI < Test::Unit::TestCase
  def test_help_cli
    output = with_captured_stdout do
      main(['--help'])
    end
    assert_true(output.start_with?('Usage:'))
  end
end
