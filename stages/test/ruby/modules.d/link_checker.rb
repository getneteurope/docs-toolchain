require "net/http"
require_relative "../extension_manager.rb"
require_relative "../base_module.rb"

module Toolchain
  class LinkChecker < BaseModule
    def run(document)
      errors = []
      links = document.references[:links]
      links.each do |link|
        resp = Net::HTTP.get_response(URI(link))
        if resp.code != "200"
          msg = "Link #{link} is invalid: [#{resp.code}] #{resp.message}"
          errors << createError(msg: msg, filename: document.attr("docfile"))
        end
      end
      return errors
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::LinkChecker.new)
