# frozen_string_literal: true

require 'test/unit'
require 'git'
require 'date'
require_relative './util.rb'
require_relative '../lib/utils/git.rb'

class TestGit < Test::Unit::TestCase
  def test_parse_ref
    a = 'master'
    b = 'fallback'
    c = 'head/refs/master'
    assert_equal(a, Toolchain::Git.parse_ref(a, b))
    assert_equal(b, Toolchain::Git.parse_ref(nil, b))
    assert_equal('master', Toolchain::Git.parse_ref(c, nil))
    assert_nil(Toolchain::Git.parse_ref(nil, nil))
  end

  def test_git_info_full
    git_info = nil
    ref_name = 'Bot McBotster'
    ref_email = 'automated@mcbotster.bot'
    ref_time = nil

    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        repo = Git.init
        repo.config('user.name', ref_name)
        repo.config('user.email', ref_email)

        repo.branch('master')
        File.open('test.txt', 'w+') { |f| f.puts("Test") }
        repo.add('test.txt')
        repo.commit('message')
        ref_time = DateTime.now.strftime(Toolchain::Git.time_format)

        ENV['CONTENT_PATH'] = tmp
        git_info = Toolchain::Git.generate_info
        ENV.delete('CONTENT_PATH')
      end
    end

    not_available = '<N/A>'
    assert_equal("#{ref_name} <#{ref_email}>", git_info.author)
    assert_match(/[0-9a-f]{40}/, git_info.commit)
    assert_equal('master', git_info.branch)
    assert_in_delta(ref_time.to_i, git_info.time.to_i, 10)
  end

  def test_git_info_na
    git_info = nil
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        ENV['CONTENT_PATH'] = tmp
        git_info = Toolchain::Git.generate_info
        ENV.delete('CONTENT_PATH')
      end
    end

    not_available = '<N/A>'
    assert_equal(not_available, git_info.author)
    assert_equal(not_available, git_info.commit)
    assert_equal(not_available, git_info.branch)
    assert_equal(not_available, git_info.time)
  end
end
