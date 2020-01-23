# frozen_string_literal: true

require 'singleton'

module Toolchain
  # ExtensionManager
  # used to register extensions based on base_extension,
  # which are run on every file.
  class ExtensionManager
    include Singleton

    ##
    # Register an extension +ext+ with the +ExtensionManager+.
    #
    # Returns nothing.
    #
    def register(ext)
      @extensions << ext
    end

    ##
    # Return the list of registered extensions.
    #
    def get
      return @extensions
    end

    ##
    # Return the next id.
    def next_id
      return @id += 1
    end

    ##
    # Clear the internal state, reset to default state.
    # Returns nothing.
    def clear
      @extensions.clear
      @id = 0
    end

    private

    def initialize
      @extensions = []
      @id = 0
    end
  end
end
