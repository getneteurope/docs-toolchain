# frozen_string_literal: true

require 'optparse'
require 'json'
require 'net/http'
require 'singleton'
require_relative '../config_manager.rb'
require_relative '../log/log.rb'
require_relative '../utils/git.rb'

##
# Toolchain module
#
module Toolchain
  ##
  # Notify module
  #
  # Umbrella namespace for all notification connectors
  module Notify
    ##
    # *Slack class*
    #
    # Class representing a messaging connection to a Slack token.
    #
    # = Example
    # <code>
    # require_relative './lib/notify/slack.rb'
    # Toolchain::Notify::Slack.instance.add('My test message')
    # Toolchain::Notify::Slack.instance.send
    # </code>
    #
    class Slack
      include Singleton

      ##
      # Add a message +msg+ to the Slack message file.
      #
      # Returns nothing.
      def add(msg)
        # load json
        json = nil
        File.open(@file, 'r') do |msg_file|
          json = JSON.load(msg_file)
        end

        # add text to json
        json['blocks'] << template(msg)
        json['blocks'] << @divider

        # write json to file again
        File.open(@file, 'w') do |msg_file|
          msg_file.write(JSON.dump(json))
        end
      end

      ##
      # Send the message defined in +@file+ to the Slack channel
      # in +ENV['SLACK_TOKEN']+.
      #
      # Returns nothing.
      def send
        token = ENV['SLACK_TOKEN']
        debug = ENV['DEBUG']
        msg = nil
        File.open(@file, 'r') do |msg_file|
          msg = JSON.load(msg_file)
        end

        closing = { 'type' => 'context', 'elements' => [
          { 'type' => 'mrkdwn',
            'text' => "Sent from <https://github.com/#{ENV['GITHUB_REPOSITORY']}|Github Actions>" }
        ] }
        msg['blocks'] << closing unless msg['blocks'].last['type'] == 'context'

        if token.nil? || debug
          log('SLACK', 'No $SLACK_TOKEN: printing to stdout') if token.nil?
          log('SLACK', 'DEBUG mode is on: printing to stdout') if debug
          puts(msg.to_json)
          return
        end

        # request to slack
        log('SLACK', 'Sending message...')
        url = "https://hooks.slack.com/services/#{token}"
        # url = 'http://requestbin.net/r/1alhka81'
        uri = URI(url)
        req = Net::HTTP::Post.new(uri, 'Content-type' => 'application/json')
        req.body = JSON.pretty_generate(msg) # JSON.dump(msg) # .encode('ASCII', 'UTF-8')
        puts req.body
        res = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(req)
        end
        log('SLACK', "Status code: [#{res.code}] #{res.message}")
      end

      private

      def initialize
        @file = ENV['SLACK_MSG_FILE'] ||
          Toolchain::ConfigManager.instance.get('notify.slack.file') ||
          '/tmp/slack.json'
        @divider = { 'type' => 'divider' }
        init
      end

      ##
      # Returns a Slack template with +msg+ as message part.
      # Returned format it Slack-readable JSON.
      #
      def template(msg)
        return { 'type' => 'section', 'text' => { 'type' => 'mrkdwn', 'text' => msg.to_s } }
      end

      ##
      # *MUST* be called before the first use.
      # Initializes all needed variables like +content_path+, but
      # also creates a +git_info+ struct used attach author and commit
      # information to the message.
      #
      def init
        git_info = Toolchain::Git.generate_info

        # format the header using the git info hash map
        commit_url = "https://github.com/#{ENV['GITHUB_REPOSITORY']}/commit/#{git_info.commit}"
        header = [
          "*Author:* #{git_info.author}",
          "*Branch:* `#{git_info.branch}`",
          "*Commit:* `#{git_info.commit}` (<#{commit_url}|Link>)",
          "*Time:* #{git_info.time}"
        ].join("\n")

        # generate the basic json structure and write it to the file
        msg = { 'blocks' => [template(header), @divider] }
        File.open(@file, 'w+') do |msg_file|
          msg_file.write(JSON.pretty_generate(msg))
        end
      end
    end
  end
end
