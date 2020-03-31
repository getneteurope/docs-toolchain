# frozen_string_literal: true

require 'test/unit'
require_relative '../../lib/stages/test.rb'
require_relative '../../lib/base_extension.rb'

class TestLocation < Test::Unit::TestCase
  def test_to_s
    loc = Toolchain::Location.new('test.adoc', 12)
    assert_equal('test.adoc:12', loc.to_s)
  end
end

class TestBaseExtension < Test::Unit::TestCase
  def test_run
    assert_raise(NotImplementedError) do
      Toolchain::BaseExtension.new.run(nil)
    end
  end
end
