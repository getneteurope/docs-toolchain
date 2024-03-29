# frozen_string_literal: true

require 'yaml'
require 'singleton'
require_relative './log/log.rb'

##
# Merge two hashes +left+ and +right+ recursively
#
# Merge strategy: right join
#
# Returns merged hash.
#
def merge_recursively(left, right)
  return right unless left.is_a?(Hash)

  return left.merge(right) do |_, left_item, right_item|
    merge_recursively(left_item, right_item)
  end
end

##
# Get a certain value in a hash of hashes.
#
# The key is described by +keys+, an array of keys representing
# the path through the hash of hashes, called +map+.
#
# Returns the corresponding value or nil.
#
def get_recursively(map, keys)
  return nil if map.nil?

  key = keys.shift
  return map[key] if keys.empty?

  return get_recursively(map[key], keys)
end

module Toolchain
  ##
  # Central class keeping track of all configuration options.
  #
  # Configurations can be changed via certain files or direct calls
  # to +ConfigManager+.
  #
  class ConfigManager
    include Singleton

    ##
    # Load configuration from +file+.
    #
    # Returns the configuration as hash (YAML parsed)
    def load(file = nil)
      file = file.nil? ? File.join(Toolchain.content_path, 'config.yaml') : file
      unless File.exist?(file)
        file = File.join(Toolchain.toolchain_path, 'config', 'default.yaml')
        log('CONFIG', "loading backup config @ #{file}")
      end

      @config = YAML.load_file(file)
      @loaded = true
    end

    ##
    # Update current configuration with configuration from +file+.
    #
    # Merging of the configuration options is with a _right join_,
    # i.e. the new +file+ options overwrite old ones.
    #
    # Returns the updated configuration as hash (YAML parsed)
    def update(file)
      update = YAML.load_file(file)
      @config = merge_recursively(@config, update)
    end

    ##
    # Get the configuration value for a key +identifier+.
    #
    # The +identifier+ is a string in the format _key1.key2.key3_,
    # where keyX is the key for the Xth level of the +@config+ hash.
    #
    # The named parameter +default+ will be used as fallback if set.
    #
    # Returns the corresponding value for +identifier+.
    # Returns +@config+ if +identifier+ is nil.
    # Returns +default+ if result is nil and +identifier+ is not nil.
    def get(identifier = nil, default: nil)
      return @config if identifier.nil?

      keys = identifier.split('.')
      return get_recursively(@config, keys) || default
    end

    ##
    # Delete the currently loaded configuration.
    #
    # Does NOT affect the files from which the config was loaded,
    # only the current state of the +ConfigManager+.
    #
    # Returns nothing.
    #
    def clear
      @config = nil
      @loaded = false
    end

    ##
    # Check whether the field at +field+ contains +value+.
    #
    # Return true or false.
    #
    def contains?(field, value)
      return (get(field) || []).include?(value)
    end

    ##
    # Get or set all attributes
    def all_attributes(attribs = nil)
      attribs.nil? || @all_attribs = attribs
      return @all_attribs
    end

    private

    def initialize
      @loaded = false
      @config = nil
      @all_attributes = all_attributes
      load
    end
  end
end
