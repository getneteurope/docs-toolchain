# frozen_string_literal: true

require 'yaml'
require 'singleton'

def merge_recursively(a, b)
  return b unless a.is_a?(Hash)

  return a.merge(b) do |_, a_item, b_item|
    merge_recursively(a_item, b_item)
  end
end

def get_recursively(map, keys)
  return nil if map.nil?

  key = keys.shift
  return map[key] if keys.empty?

  return get_recursively(map[key], keys)
end

module Toolchain
  class ConfigManager
    include Singleton

    def load(file)
      return @config = YAML.load_file(file)
    end

    def update(file)
      update = YAML.load_file(file)
      return @config = merge_recursively(@config, update)
    end

    def get(identifier = nil)
      return @config if identifier.nil?

      keys = identifier.split('.')
      return get_recursively(@config, keys)
    end
  end
end
