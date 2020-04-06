# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/utils/string.rb'
require_relative './util.rb'

class TestString < Test::Unit::TestCase
  COLORS = %i[black red green yellow blue magenta cyan gray]
  def test_colors
    text = 'Test'
    COLORS.each do |color|
      colorized = text.public_send(color)
      assert_not_nil(colorized)
      assert_match(text, colorized)
    end
  end

  def test_bg_colors
    colors = COLORS.map { |s| "bg_#{s}".to_sym }
    text = 'Test'
    colors.each do |color|
      colorized = text.public_send(color)
      assert_not_nil(colorized)
      assert_match(text, colorized)
    end
  end

  def test_modifiers
    modifiers = %i[bold italic underline blink reverse_color]
    text = 'Test'
    modifiers.each do |modifier|
      modified = text.public_send(modifier)
      assert_not_nil(modified)
      assert_match(text, modified)
    end
  end

  def test_colorize
    text = 'Test'
    COLORS.each do |color|
      colorized = colorize(text, color)
      assert_not_nil(colorized)
      assert_match(text, colorized)
    end
  end
end
