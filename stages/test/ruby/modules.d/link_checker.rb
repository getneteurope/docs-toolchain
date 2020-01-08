require "net/http"
require_relative "../extension_manager.rb"
require_relative "../base_extension.rb"

module Toolchain
  class LinkChecker < BaseExtension
    def run(document)
      errors = []
      links = document.references[:links]
      links.each do |link|
        begin
          # puts "Test #{link}".cyan.bold
          resp = nil
          uri = URI(link)
          # Net::HTTP.new(uri.host, uri.port) do |http|
          http = Net::HTTP.new(uri.host, uri.port)
          http.open_timeout = 5
          http.read_timeout = 5
          http.write_timeout = 5
          http.use_ssl = true if link =~ /^https/
          http.start
          resp = http.request(Net::HTTP::Get.new(uri))
          # end
          # resp = Net::HTTP.get_response(uri)
          msg = nil
        rescue SocketError => se
          idx = se.message.index("(") - 1
          msg = "#{se.class.name}: #{se.message[0..idx]}"
        rescue Net::OpenTimeout => ot
          msg = "#{ot.class.name}: #{ot.message} for #{link}"
        end

        if msg.nil? and not resp.nil? and resp.code != "200"
          msg = "[#{resp.code}] #{resp.message}: #{link}"
        end

        msg = "Unknown error: Response is nil" if msg.nil? and resp.nil?
        errors << createError(msg: msg, filename: document.attr("docfile")) unless msg.nil?
      end
      return errors
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::LinkChecker.new)
