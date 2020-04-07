# frozen_string_literal: true

require 'test/unit'
require_relative '../../lib/extensions.d/if_checker.rb'
require_relative '../util.rb'

class TestIfChecker < Test::Unit::TestCase
  def test_simple_if
    content = '== Section 2

    Help me figure this out.
    Thanks!
    '.gsub('    ', '')
    include_adoc = init(content, "#{self.class.name}_#{__method__}_include")

    content = "= Header 1 - Main
    :do-include: fralle
    ifdef::do-include[]
    include::#{include_adoc.filename}[]
    endif::[]
    Lorem ipsum blabla di blabla du.
    ".gsub('    ', '')
    main_adoc = init(content, "#{self.class.name}_#{__method__}_main")

    Dir.chdir('/tmp') do
      errors = Toolchain::IfChecker.new.run(main_adoc)
      assert_empty(errors)
    end
  end

  def test_nested_if
    content = "= Header 1 - Main
    :do-include: fralle
    :include2: yes
    :another-one: dj-khaled
    ifdef::do-include[]
    = Header 2
    This is another section.
    ifdef::include2[]
    == Let's go down
    I am a submarine.
    ifdef::another-one[]
    == Let's play a game
    Bravo Six, goin' dark.
    endif::[]
    endif::[]
    endif::[]
    Lorem ipsum blabla di blabla du.
    ".gsub('    ', '')
    main_adoc = init(content, "#{self.class.name}_#{__method__}_main")

    Dir.chdir('/tmp') do
      errors = Toolchain::IfChecker.new.run(main_adoc)
      assert_empty(errors)
    end
  end

  def test_missing_close
    content = "= Header 1 - Main
    :do-include: fralle
    :include2: yes
    :another-one: dj-khaled
    ifdef::do-include[]
    = Header 2
    This is another section.
    ifdef::include2[]
    == Let's go down
    I am a submarine.
    ifdef::another-one[]
    == Let's play a game
    Bravo Six, goin' dark.
    endif::[]
    endif::[]
    Lorem ipsum blabla di blabla du.
    ".gsub('    ', '')
    main_adoc = init(content, "#{self.class.name}_#{__method__}_main")

    Dir.chdir('/tmp') do
      errors = Toolchain::IfChecker.new.run(main_adoc)
      assert_equal(1, errors.length)
      assert_equal(4, errors.first[:location].lineno)
      assert_match(/unmatched ifdef found/, errors.first[:msg])
    end
  end

  def test_missing_open
    content = "= Header 1 - Main
    :do-include: fralle
    :include2: yes
    :another-one: dj-khaled
    ifdef::do-include[]
    = Header 2
    This is another section.
    ifdef::include2[]
    == Let's go down
    I am a submarine.
    == Let's play a game
    Bravo Six, goin' dark.
    endif::[]
    endif::[]
    endif::[]
    Lorem ipsum blabla di blabla du.
    ".gsub('    ', '')
    main_adoc = nil
    with_captured do # suppress asciidoctor errors
      main_adoc = init(content, "#{self.class.name}_#{__method__}_main")
    end

    Dir.chdir('/tmp') do
      errors = Toolchain::IfChecker.new.run(main_adoc)
      assert_equal(1, errors.length)
      assert_equal(14, errors.first[:location].lineno)
      assert_match(/unmatched endif found/, errors.first[:msg])
    end
  end
end

