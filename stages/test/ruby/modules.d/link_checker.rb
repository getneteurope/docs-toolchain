# frozen_string_literal: true

require 'net/http'
require_relative '../extension_manager.rb'
require_relative '../base_extension.rb'

module Toolchain
  class LinkChecker < BaseExtension
    def run(document)
      puts 'Running Link Checks'
      errors = []
      links = document.references[:links]
      links.each do |link|
        msg = test_link(link)
        errors << create_error(msg: msg, filename: document.attr('docfile')) unless msg.nil?
      end
      return errors
    end

    private

    def test_link(link)
      msg = nil
      resp = nil
      begin
        resp = get_response(link)
        msg = "[#{resp.code}] #{resp.message}: #{link}" if !resp.nil? && resp.code != '200'
        msg = 'Unknown error: response is nil' if resp.nil?
      rescue StandardError => e
        msg = format_exception(e, link)
      end

      return msg
    end

    def get_response(link)
      uri = URI(link)
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 5
      http.read_timeout = 5
      http.write_timeout = 5
      http.use_ssl = true if link =~ /^https/
      http.start
      return http.request(Net::HTTP::Get.new(uri))
    end

    def format_exception(exc, link)
      case exc
      when SocketError
        idx = exc.message.index('(') - 1
        return "#{exc.class.name}: #{exc.message[0..idx]}"
      when Net::OpenTimeout
        return "#{exc.class.name}: #{exc.message} for #{link}"
      else
        return "Unknown Exception: #{exc.message}"
      end
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::LinkChecker.new)
