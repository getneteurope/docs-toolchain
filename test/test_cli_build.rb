# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/stages/build.rb'
require_relative '../lib/cli.rb'
require_relative './util.rb'


class TestBuildCLI < Test::Unit::TestCase
  def initialize(test_method_name)
    super(test_method_name)
    @default_content = 'content'
    @default_index = 'index.adoc'
  end

  def test_default
    args, = Toolchain::Build::CLI.parse_args([])
    assert_false(args.help)
    assert_false(args.debug)
    assert_equal(@default_content, args.content)
    assert_equal(@default_index, args.index)
  end

  def test_help
    args, = Toolchain::Build::CLI.parse_args(%w[--help])
    assert_true(args.help)
    assert_false(args.debug)
    assert_equal(@default_content, args.content)
    assert_equal(@default_index, args.index)
  end

  def test_debug
    args, = Toolchain::Build::CLI.parse_args(%w[--debug])
    assert_false(args.help)
    assert_true(args.debug)
    assert_equal(@default_content, args.content)
    assert_equal(@default_index, args.index)
  end

  def test_content
    args, = Toolchain::Build::CLI.parse_args(%w[--content mycontent])
    assert_false(args.help)
    assert_false(args.debug)
    assert_equal('mycontent', args.content)
    assert_equal(@default_index, args.index)
  end

  def test_index
    args, = Toolchain::Build::CLI.parse_args(%w[--index myindex.adoc])
    assert_false(args.help)
    assert_false(args.debug)
    assert_equal(@default_content, args.content)
    assert_equal('myindex.adoc', args.index)
  end
end
