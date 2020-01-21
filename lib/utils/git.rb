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

      return ref.split('/').last if ref.count('/')

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
    def self.generate_info
      content_path = '.'
      # only works with content repository
      content_path = File.join(ENV['TOOLCHAIN_PATH'], '..') if ENV['TOOLCHAIN_PATH']
      # fix Github CI error when testing toolchain only (no content repo)
      content_path = ENV['GITHUB_WORKSPACE'] if ENV['GITHUB_WORKSPACE']
      # parse git info of latest commit
      repo = ::Git.open(File.join(content_path, '..')) if content_path
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
      return git_info
    end
  end
end
