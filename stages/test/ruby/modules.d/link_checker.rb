# frozen_string_literal: true

require 'net/http'
require_relative '../extension_manager.rb'
require_relative '../base_extension.rb'

module Toolchain
  class LinkChecker < BaseExtension
    def run(document)
      errors = []
      links = document.references[:links]
      links.each do |link|
        begin
          # puts 'Test #{link}'.cyan.bold
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
        rescue SocketError => e
          idx = e.message.index('(') - 1
          msg = "#{e.class.name}: #{e.message[0..idx]}"
        rescue Net::OpenTimeout => e
          msg = "#{e.class.name}: #{e.message} for #{link}"
        end

        msg = "[#{resp.code}] #{resp.message}: #{link}" if msg.nil? && !resp.nil? && resp.code != '200'

        msg = 'Unknown error: Response is nil' if msg.nil? && resp.nil?
        errors << createError(msg: msg, filename: document.attr('docfile')) unless msg.nil?
      end
      return errors
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::LinkChecker.new)
