# frozen_string_literal: true

require 'git'
require 'ostruct'

module Toolchain
  ##
  # Git module
  #
  # Umbrella module for all Git related actions.
  module Git
    ##
    # Pass a reference +ref+ and a fallback +fallback+ and return
    # the parsed reference.
    #
    # Reference, in this case, describes a git reference like a branch name
    # or a tag.
    # Depending on the environment this reference can occur in
    # many different places.
    #
    # Returns a parsed reference or fallback if no reference was found.
    #
    def self.parse_ref(ref = ENV['GITHUB_REF'], fallback = nil)
      return fallback unless ref

      return ref.split('/').last unless ref.count('/').zero?

      return ref
    end

    ##
    # Generate a hash containing Git information:
    # [author]       author name and email
    # [commit]       commit hash
    # [branch]       git reference (branch or tag)
    # [time]         commit time and date
    #
    # The path of the git repo is controlled by ENV: $PWD > $TOOLCHAIN_PATH/..
    #
    # Returns a OpenStruct containing the information described above.
    def self.generate_info(path = nil)
      content_path = '..'
      content_path = ENV['GITHUB_WORKSPACE'] \
        if ENV.key?('TOOLCHAIN_TEST') || ENV.key?('GITHUB_ACTIONS')
      # Unit testing
      content_path = path unless path.nil?

      git_info = nil
      begin
        # parse git info of latest commit
        repo = ::Git.open(content_path)
        head = repo.object('HEAD').sha
        commit = repo.gcommit(head)
        author = commit.author
        branch = parse_ref(
          ENV['GITHUB_REPOSITORY'],
          repo.remote('origin')
        ) || repo.revparse(commit.sha)

        git_info = OpenStruct.new(
          author: "#{author.name} <#{author.email}>",
          commit: commit.sha,
          branch: branch.to_s,
          time: commit.date.strftime('%H:%M %d.%m.%Y')
        )
      rescue StandardError => _e
        log('GIT', "Error opening Git repository at #{content_path}")
        hash = {}
        %i[author commit branch time].each do |key|
          hash[key] = '<N/A>'
        end
        git_info = OpenStruct.new(hash)
      end
      return git_info
    end
  end
end
