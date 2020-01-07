require 'singleton'

module Toolchain
  class ExtensionManager
    include Singleton
    @instance = nil

    def instance
      @instance = ExtensionManager.new if @instance.nil?
      return @instance
    end

    def register(ext)
      @extensions << ext
    end

    def get
      return @extensions
    end

    def nextId
      @id += 1
      return @id
    end

    private

    def initialize
      @extensions = []
      @id = 0
    end
  end
end
