# frozen_string_literal: true

require 'optparse'
require 'ostruct'
require 'json'
require 'git'
require 'net/http'
require_relative '../config_manager.rb'
require_relative '../log/log.rb'

##############################################################
# EXAMPLE
##############################################################
# require_relative './lib/notify/slack.rb'
# Toolchain::Notify::Slack::Messenger.init
# Toolchain::Notify::Slack::Messenger.add('My test message')
# Toolchain::Notify::Slack::Messenger.send
##############################################################

def _parse_ref(ref = ENV['GITHUB_REF'])
  return ref.split('/').last if ref&.count('/')

  return ref
end

module Toolchain
  module Notify
    module Slack
      # module CLI
      #   def self.parse_args(argv = ARGV)
      #     args = {debug: false, msg: [], send: false}
      #     opt_parser = OptionParser.new do |parser|
      #       parser.banner = 'Usage: ./slack.rb [options]'

      #       parser.on('-d', '--debug', 'enable debug mode') do
      #         args[:debug] = true
      #       end

      #       parser.on('-a MSG', '--add MSG', 'add a message to the JSON file') do |msg|
      #         args[:msg] << msg
      #       end

      #       parser.on('--send', 'send the message (using environment variable SLACK_TOKEN)') do
      #         args[:send] = true
      #       end
      #     end
      #     opt_parser.parse(argv)
      #     return OpenStruct.new(args)
      #   end
      # end

      class Messenger
        @@file = nil
        @@divider = { 'type' => 'divider' }

        def self.template(msg)
          return { 'type' => 'section', 'text' => { 'type' => 'mrkdwn', 'text' => msg.to_s } }
        end

        def self.init
          content_path = '.'
          content_path = File.join(ENV['TOOLCHAIN_PATH'], '..') if ENV['TOOLCHAIN_PATH']
          # parse git info of latest commit
          repo = Git.open(File.join(content_path, '..')) if content_path
          head = repo.object('HEAD').sha
          commit = repo.gcommit(head)
          author = commit.author
          branch = _parse_ref(
            ENV['GITHUB_REPOSITORY'],
            repo.remote('origin')
          ) || repo.revparse(commit.sha)

          git_info = OpenStruct.new(
            author: "#{author.name} <#{author.email}>",
            commit: commit.sha,
            branch: branch.to_s,
            time: commit.date.strftime('%H:%M %d.%m.%Y')
          )

          # set the slack message file if it is not set yet
          if @@file.nil?
            @@file = Toolchain::ConfigManager.instance.get('notify.slack.file')
            @@file = '/tmp/slack.json' if @@file.nil?
          end

          # format the header using the git info hash map
          commit_url = "https://github.com/#{ENV['GITHUB_REPOSITORY']}/commit/#{git_info.commit}"
          header = [
            "*Author:* #{git_info.author}",
            "*Branch:* `#{git_info.branch}`",
            "*Commit:* `#{git_info.commit}` (<#{commit_url}|Link>)",
            "*Time:* #{git_info.time}"
          ].join("\n")

          # generate the basic json structure and write it to the file
          msg = { 'blocks' => [template(header), @@divider] }
          File.open(@@file, 'w+') do |f|
            f.write(JSON.pretty_generate(msg))
          end
        end

        def self.add(msg)
          init if @@file.nil?

          # load json
          json = nil
          File.open(@@file, 'r') do |f|
            json = JSON.load(f)
          end

          # add text to json
          json['blocks'] << template(msg)
          json['blocks'] << @@divider

          # write json to file again
          File.open(@@file, 'w') do |f|
            f.write(JSON.dump(json))
          end
        end

        def self.send
          raise 'Nothing added, cannot send a message' if @@file.nil?

          token = ENV['SLACK_TOKEN']
          debug = ENV['DEBUG']
          msg = nil
          File.open(@@file, 'r') do |f|
            msg = JSON.load(f)
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
          req.body = JSON.dump(msg)
          puts req.body
          res = Net::HTTP.start(uri.hostname, uri.port) do |http|
            http.request(req)
          end
          log('SLACK', "Status code: [#{res.code}] #{res.message}")
        end
      end
    end
  end
end
