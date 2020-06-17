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
      return "Unknown Exception: #{msg} for #{link}"
    end
  end

  ##
  # Link Checker
  #
  # Check links and detect whether a link is dead, has moved, cannot be reached, etc.
  class LinkChecker < BaseExtension
    ATTR_REGEX = /^.*\{(.+)\}.*$/.freeze
    ##
    # Run the Link tests on the given document (+adoc+).
    #
    # Returns a list of errors (can be empty).
    #
    def run(adoc)
      parsed = adoc.parsed
      @attributes = (::Toolchain::ConfigManager.instance.all_attributes || {}).merge(adoc.attributes)
      errors = []
      # TODO: links does not contain resolved links with attributes e.g. https://{domain}.com. find out why and fix
      links = parsed.references[:links]
      links.each do |link|
        next unless link =~ /^https?:.+/
        link = attr_replace(link)
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
    # Replace attributes in links
    #
    # Returns the replaced +link+
    def attr_replace(link)
      if ATTR_REGEX.match? link
        key = link.gsub ATTR_REGEX, '\1'
        if @attributes.keys.any? key
          attrib = @attributes[key]
          link = link.gsub(/\{.+\}/, attrib)
        end
      end
      link
    end

    ##
    # Test a +link+, i.e. try to perform a +GET+ request.
    #
    # Return nil if success, or +msg+ if an error occured.
    def test_link(link)
      # log('LINK', link, :magenta)
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
    # You can provide Net::HTTP +options+
    def get_response(link, options={})
      uri = URI(link)
      default_options = {
        read_timeout: 1,
        open_timeout: 1,
        write_timeout: 1,
        use_ssl: (link =~ /^https/)
      }
      options = default_options.merge(options)
      http = Net::HTTP.start(uri.host, uri.port, options)
      return http.request(Net::HTTP::Get.new(uri))
    end
  end
end

Toolchain::ExtensionManager.instance.register(Toolchain::LinkChecker.new)
