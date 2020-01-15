# frozen_string_literal: true

require 'yaml'
require 'singleton'

def merge_recursively(a, b)
  return a.merge(b) do |_, a_item, b_item|
    merge_recursively(a_item, b_item)
  end
end

def get(map, keys)
  key = keys.shift
  return map[key] if keys.empty?

  return get(map[key], keys)
end

module Toolchain
  class ConfigManager
    include Singleton
    def load(file = 'config/default.yaml')
      return @config = YAML.load_file(file)
    end

    def append(file)
      update = YAML.load_file(file)
      return @config = merge_recursively(@config, update)
    end

    def get(identifier)
      keys = identifier.split('.')
      return get(@config, keys)
    end

    class << self
      def load(file = 'config/default.yaml')
        return ConfigManager.instance.load(file)
      end

      def append(file)
        return ConfigManager.instance.append(file)
      end

      def get(identifier)
        return ConfigManager.instance.get(identifier)
      end
    end
  end
end
