# frozen_string_literal: true

require_relative '../utils/string.rb'

##
# Create a log entry in the format:
#     [tag] msg
# using the given color and font weight.
#
# Params:
# +tag+: The tag to display at the beginning
# +msg+: The message to log
# +color+: Define color as symbol (default: +:blue+)
# +bold+: Whether +msg+ should be bold (default: false)
# +length+: Width of the +tag+ inside the brackets (default: 14)
# +stream+: Which output stream to use (default: +STDOUT+)
#
# Returns nothing.
def log(tag, msg, color = :blue, bold = false, stream: $stdout)
  return if ENV.key?('UNITTEST') && !ENV.key?('DEBUG')

  tag = colorize(tag, color)
  tag_line = "[#{Time.now.strftime('%H:%m:%S')}]::#{tag} =>".bold
  msg = msg.bold if bold

  stream.puts "#{tag_line} #{msg}"
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
  log(stage, msg, color)
end


##
# Log error to STDOUT.
#
def error(msg)
  log('ERROR', msg, :red, stream: $stderr)
end
