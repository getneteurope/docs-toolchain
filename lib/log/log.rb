# frozen_string_literal: true

require_relative '../utils.rb'

def log(tag, msg, color=:blue, bold=false)
  return if ENV.key?('UNITTEST')

  tag = "[#{tag}]".bold
  case color
  when :black
    tag = tag.black
  when :red
    tag = tag.red
  when :green
    tag = tag.green
  when :brown
    tag = tag.brown
  when :blue
    tag = tag.blue
  when :magenta
    tag = tag.magenta
  when :cyan
    tag = tag.cyan
  when :gray
    tag = tag.gray
  end
  msg = msg.bold if bold
  puts "#{tag} #{msg}"
end

def stage_log(stage, msg, color: :green)
  stages = %w[setup test build deploy post notify]
  stage = stage.to_s.upcase
  longest = stages.max { |a, b| a.length <=> b.length }.length
  stage = ' ' * (longest - stage.length) + stage
  log(stage, msg, color, true)
end
