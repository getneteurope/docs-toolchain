# frozen_string_literal: true

require_relative '../extension_manager.rb'
require_relative '../base_extension.rb'

module Toolchain
  # ID Checker
  # check IDs according to a stricter standard than the default Asciidoctor standard
  class IdChecker < BaseExtension
    def run(document)
      # TODO: get all links and check
      puts 'Running ID Checks'
      return []
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::IdChecker.new)
