# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/stages/test.rb'
require_relative '../lib/cli.rb'
require_relative './util.rb'

class TestTestCLI < Test::Unit::TestCase
  def test_default
    args, = Toolchain::Test::CLI.parse_args([])
    assert_false(args.help)
    assert_false(args.debug)
    assert_empty(args.files)
    assert_nil(args.index)
  end

  def test_help
    args, = Toolchain::Test::CLI.parse_args(%w[--help])
    assert_true(args.help)
    assert_false(args.debug)
    assert_empty(args.files)
    assert_nil(args.index)
  end

  def test_debug
    args, = Toolchain::Test::CLI.parse_args(%w[--debug])
    assert_false(args.help)
    assert_true(args.debug)
    assert_empty(args.files)
    assert_nil(args.index)
  end

  def test_files
    args, = Toolchain::Test::CLI.parse_args(%w[--file test.adoc --file content.adoc])
    assert_false(args.help)
    assert_false(args.debug)
    assert_equal(['test.adoc', 'content.adoc'], args.files)
    assert_nil(args.index)
  end

  def test_index
    args, = Toolchain::Test::CLI.parse_args(%w[--index index.adoc])
    assert_false(args.help)
    assert_false(args.debug)
    assert_empty(args.files)
    assert_equal('index.adoc', args.index)
  end

  def test_index_and_file
    assert_raise(ArgumentError) { Toolchain::Test::CLI.parse_args(%w[--index index.adoc --file file.adoc]) }
  end
end
