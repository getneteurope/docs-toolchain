require "test/unit"
require_relative "../../stages/test/ruby/main_module.rb"
require_relative "../../stages/test/ruby/cli.rb"

# https://stackoverflow.com/a/22777806
def with_captured_stdout
  original_stdout = $stdout  # capture previous value of $stdout
  $stdout = StringIO.new     # assign a string buffer to $stdout
  yield                      # perform the body of the user code
  $stdout.string             # return the contents of the string buffer
ensure
  $stdout = original_stdout  # restore $stdout to its previous value
end

class TestCLI < Test::Unit::TestCase
  def test_help_parse
    args = parse_args(["--help"])
    assert_true(args.help)
    assert_false(args.file)
    assert_false(args.index)
    assert_false(args.debug)
  end

  def test_help_cli
    output = with_captured_stdout do
      main(["--help"])
    end
    assert_true output.start_with?('Usage:')
  end
end
