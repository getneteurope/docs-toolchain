# frozen_string_literal: true

require_relative '../utils/string.rb'

##
# Create a log entry in the format:
#     [tag] msg
# using the given color and font weight
#
# Returns nothing.
def log(tag, msg, color = :blue, bold = false, length: 14)
  return if ENV.key?('UNITTEST') && !ENV.key?('DEBUG')

  length = tag.length if length.zero?
  tag = "[#{colorize(tag.center(length), color)}]".bold
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
def stage_log(stage, msg, color = :green)
  stage = stage.to_s.upcase
  log(stage, msg, color, true)
end
