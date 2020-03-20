# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/cli.rb'
require_relative './util.rb'


class TestProcessCLI < Test::Unit::TestCase
  def test_default
    args, = Toolchain::Process::CLI.parse_args([])
    assert_false(args.help)
    assert_false(args.debug)
    assert_false(args.list)
  end

  def test_help
    args, = Toolchain::Process::CLI.parse_args(%w[--help])
    assert_true(args.help)
    assert_false(args.debug)
    assert_false(args.list)
  end

  def test_debug
    args, = Toolchain::Process::CLI.parse_args(%w[--debug])
    assert_false(args.help)
    assert_true(args.debug)
    assert_false(args.list)
  end

  def test_list
    args, = Toolchain::Process::CLI.parse_args(%w[--list])
    assert_false(args.help)
    assert_false(args.debug)
    assert_true(args.list)
  end
end
