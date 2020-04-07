# frozen_string_literal: true

require 'test/unit'
require 'git'
require_relative './util.rb'

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
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        repo = Git.init
        File.open('test.txt', 'w+') { |f| f.puts("Test") }
        repo.add('test.txt')
        repo.commit('message')
        ENV['CONTENT_PATH'] = tmp
        git_info = Toolchain::Git.generate_info
        ENV.delete('CONTENT_PATH')
      end
    end

    not_available = '<N/A>'
    assert_not_equal(not_available, git_info.author)
    assert_not_equal(not_available, git_info.commit)
    assert_not_equal(not_available, git_info.branch)
    assert_not_equal(not_available, git_info.time)
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
