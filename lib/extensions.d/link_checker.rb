# frozen_string_literal: true

require 'net/http'
require_relative '../extension_manager.rb'
require_relative '../base_extension.rb'

module Toolchain
  ##
  # Given an exception +exc+ and a link +link+, format the message which shall be displayed.
  #
  # Returns the formatted message.
  def self.format_net_exception(exc, link)
    msg = exc.message
    case exc
    when SocketError
      idx = msg.index('(') - 1
      return "#{exc.class.name}: #{msg[0..idx]}"
    when Net::OpenTimeout
      return "#{exc.class.name}: #{msg} for #{link}"
    else
      return "Unknown Exception: #{msg}"
    end
  end

  ##
  # Link Checker
  #
  # Check links and detect whether a link is dead, has moved, cannot be reached, etc.
  class LinkChecker < BaseExtension
    ##
    # Run the Link tests on the given document (+adoc+).
    #
    # Returns a list of errors (can be empty).
    #
    def run(adoc)
      parsed = adoc.parsed
      errors = []
      links = parsed.references[:links]
      links.each do |link|
        msg = test_link(link)
        next if msg.nil?

        errors << create_error(
          msg: msg, location: Location.new(parsed.attr('docfile'), nil)
        )
      end
      return errors
    end

    private

    ##
    # Test a +link+, i.e. try to perform a +GET+ request.
    #
    # Return nil if success, or +msg+ if an error occured.
    def test_link(link)
      log('LINK', link, :magenta)
      msg = nil
      resp = nil
      begin
        resp = get_response(link)
        msg = "[#{resp.code}] #{resp.message}: #{link}" if !resp.nil? && resp.code != '200'
        msg = 'Unknown error: response is nil' if resp.nil?
      rescue StandardError => e
        msg = Toolchain.format_net_exception(e, link)
      end

      return msg
    end

    ##
    # Send a +GET+ request to +link+ and return the result.
    def get_response(link)
      uri = URI(link)
      http = Net::HTTP.new(uri.host, uri.port)
      timeout = 0.8
      http.open_timeout = timeout
      http.read_timeout = timeout
      http.write_timeout = timeout
      http.use_ssl = true if link =~ /^https/
      http.start
      return http.request(Net::HTTP::Get.new(uri))
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::LinkChecker.new)
