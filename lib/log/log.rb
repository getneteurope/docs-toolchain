# frozen_string_literal: true

require_relative '../utils.rb'

##
# Colorize +text+ in the color specified by +color+.
#
# Returns the colorized string
def colorize(text, color)
  case color
  when :black
    text = text.black
  when :red
    text = text.red
  when :green
    text = text.green
  when :brown
    text = text.brown
  when :blue
    text = text.blue
  when :magenta
    text = text.magenta
  when :cyan
    text = text.cyan
  when :gray
    text = text.gray
  end
  return text
end

##
# Create a log entry in the format:
#     [tag] msg
# using the given color and font weight
#
# Returns nothing.
def log(tag, msg, color = :blue, bold = false)
  return if ENV.key?('UNITTEST')

  tag = "[#{colorize(tag, color)}]".bold
  msg = msg.bold if bold
  puts "#{tag} #{msg}"
end

##
# Create a log entry for a given stage.
#
# The stage is defined by +stage+, and will be formated like:
#        [stage] msg
# using the given color.
#
# Returns nothing.
def stage_log(stage, msg, color: :green)
  stages = %w[setup test build deploy post notify]
  stage = stage.to_s.upcase
  longest = stages.max { |left, right| left.length <=> right.length }.length
  stage = ' ' * (longest - stage.length) + stage
  log(stage, msg, color, true)
end
