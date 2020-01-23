# frozen_string_literal: true

require 'test/unit'
require 'git'

class TestGit < Test::Unit::TestCase
  def test_parse_ref
    a = 'a'
    b = 'b'
    c = 'a/b/c'
    assert_equal(a, Toolchain::Git.parse_ref(a, b))
    assert_equal(b, Toolchain::Git.parse_ref(nil, b))
    assert_equal('c', Toolchain::Git.parse_ref(c, nil))
    assert_nil(Toolchain::Git.parse_ref(nil, nil))
  end

  def test_git_info_full
    ENV.delete('TOOLCHAIN_PATH')
    ENV.delete('GITHUB_WORKSPACE')
    git_info = Toolchain::Git.generate_info
    not_available = '<N/A>'
    assert_not_equal(git_info.author, not_available)
    assert_not_equal(git_info.commit, not_available)
    assert_not_equal(git_info.branch, not_available)
    assert_not_equal(git_info.time, not_available)
  end

  def test_git_info_empty
    ENV['GITHUB_WORKSPACE'] = 'asgasdg71243234'
    git_info = Toolchain::Git.generate_info
    not_available = '<N/A>'
    assert_equal(git_info.author, not_available)
    assert_equal(git_info.commit, not_available)
    assert_equal(git_info.branch, not_available)
    assert_equal(git_info.time, not_available)
  end
end
