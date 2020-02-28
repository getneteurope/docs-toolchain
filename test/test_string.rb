# frozen_string_literal: true

require_relative '../lib/utils/string.rb'
require 'test/unit'

class TestString < Test::Unit::TestCase
  def test_colors
    colors = %i[black red green brown blue magenta cyan gray]
    text = 'Test'
    colors.each do |color|
      colorized = text.public_send(color)
      assert_not_nil(colorized)
      assert_match(text, colorized)
    end
  end

  def test_bg_colors
    colors = \
      %w[black red green brown blue magenta cyan gray].map { |s| "bg_#{s}".to_sym }
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
    colors = %i[black red green brown blue magenta cyan gray]
    text = 'Test'
    colors.each do |color|
      colorized = colorize(text, color)
      assert_not_nil(colorized)
      assert_match(text, colorized)
    end
  end
end
