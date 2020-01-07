require_relative '../extension_manager.rb'
require_relative '../base_module.rb'

module Toolchain
  class IdChecker < BaseModule
    def run(document)
      # TODO: get all links and check
      puts "Running ID Checks"
      return []
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::IdChecker.new)
