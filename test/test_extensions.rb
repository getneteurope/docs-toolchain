# frozen_string_literal: true

require 'asciidoctor'
require 'test/unit'
require_relative '../lib/stages/test.rb'
require_relative '../lib/log/log.rb'
require_relative './util.rb'
require_relative '../lib/utils/create_toc.rb'

extensions = File.join(__dir__, '..', 'lib', 'extensions.d', '*.rb')
Dir[extensions].each { |file| require file }

class TestLocation < Test::Unit::TestCase
  def test_to_s
    loc = Toolchain::Location.new('test.adoc', 12)
    assert_equal('test.adoc:12', loc.to_s)
  end
end

class TestBaseExtension < Test::Unit::TestCase
  def test_run
    assert_raise(NotImplementedError) do
      Toolchain::BaseExtension.new.run(nil)
    end
  end
end

class TestIDChecker < Test::Unit::TestCase
  def test_short_ids
    wrong_ref = %w[illegal_$ign my_se¢tion]
    adoc_content = '= Test IDs
[#first]
== First
This is my first section.

[#illegal_$ign]
== Sign
Sign here please.

[#my_se¢tion]
=== My Section

Here is my very own section.
Thank you.
    '
    adoc = init(adoc_content, "#{self.class.name}_#{__method__}")
    errors = Toolchain::IdChecker.new.run(adoc)
    assert_equal(2, errors.length)
    wrong_ids = parse(errors)
    assert_equal(wrong_ref, wrong_ids)
  end

  def test_long_ids
    wrong_ref = %w[illegal_$ign my_se¢tion]
    adoc_content = '= Test IDs
[[first]]
== First
This is my first section.

[[illegal_$ign]]
== Sign
Sign here please.

[[my_se¢tion]]
=== My Section

Here is my very own section.
Thank you.
    '
    adoc = init(adoc_content, "#{self.class.name}_#{__method__}")
    errors = Toolchain::IdChecker.new.run(adoc)
    assert_equal(2, errors.length)
    wrong_ids = parse(errors)
    assert_equal(wrong_ref, wrong_ids)
  end

  def test_attributes_in_anchors
    inc1_adoc = ':bad_anchor: bad_chapter _anchor
:good_anchor: this_is_good
=== Boo
soome text
    '

    inc2_adoc = '=== chapter 2
one more chapter with invalid ANCHOR
hui
[#{good_anchor}]
== some
text
[[hardcoded]]
[#{bad_anchor}]
== heading in chapter 2
    '
    attr_in_anchors_inc1_file_name = File.basename write_tempfile('attributes_in_anchors_inc1.adoc', inc1_adoc)
    attr_in_anchors_inc2_file_name = File.basename write_tempfile('attributes_in_anchors_inc2.adoc', inc2_adoc)

    adoc_content = ":env-payment-processor:
index text
include::#{attr_in_anchors_inc1_file_name}[]
filler
include::#{attr_in_anchors_inc2_file_name}[]

//- comment
    "
    #attr_in_anchors_filepath = write_tempfile('attributes_in_anchors.adoc', adoc_content)
    adoc = init(adoc_content, "#{self.class.name}_#{__method__}")
    errors = Toolchain::IdChecker.new.run(adoc)
    assert_equal(1, errors.length)
    assert_match /bad_chapter _anchor/, errors[0][:msg]
  end

  private

  def parse(errors)
    return errors.map do |err|
      msg = err[:msg]
      startc = msg.index("'") + 1
      endc = msg.index("'", startc) - 1
      msg[startc..endc]
    end
  end
end

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

class TestLinkChecker < Test::Unit::TestCase
  def test_links
    omit_if(ENV.key?('SKIP_NETWORK'), 'Tests with networking disabled')
    adoc_content = '= Test links

1. https://github.com/wirecard/docs-toolchain[Docs Toolchain]
2. https://github.com/asciidoctor/asciidoctor-exteansions-lab[Asciidoctor Extensions Lab]
3. https://adfasdgea.asd/adfadfasdf/[Unknown Domain]
4. http://111.222.123.48[Random IP]
    '
    adoc = init(adoc_content, "#{self.class.name}_#{__method__}")
    assert_equal(4, adoc.parsed.references[:links].length)
    errors = Toolchain::LinkChecker.new.run(adoc)
    assert_equal(3, errors.length)
    assert_any_startwith(errors, '[404] Not Found') # 2.
    assert_any_startwith(errors, 'SocketError') # 3.
    assert_any_startwith(errors, 'Net::OpenTimeout') # 4.
  end

  def test_format_net_exception
    msg = Toolchain.format_net_exception(StandardError.new('Test'), nil)
    assert_match(/Unknown Exception/, msg)
  end
end

class TestPatternBlacklist < Test::Unit::TestCase
  def test_pattern_blacklist
    adoc = '= Bad lines

======= too long heading
WPP
document-center

    '
    blacklist_patterns = '
# do not match this comment
// do not match this comment
/document-center/
/WPP/
document
/={6,}/
/bad_word/
    '
    blacklist_filepath = write_tempfile('blacklist_patterns.txt', blacklist_patterns)
    adoc = init(adoc, "#{self.class.name}_#{__method__}", 'test_toolchain_pattern_blacklist.adoc')
    errors = Toolchain::PatternBlacklist.new.run(adoc, blacklist_filepath)
    assert_equal(3, errors.length)
  end

  def test_no_blacklist
    adoc = init(adoc, "#{self.class.name}_#{__method__}", 'test_toolchain_pattern_blacklist.adoc')
    errors = Toolchain::PatternBlacklist.new.run(adoc, '/does/not/exist.txt')
    assert_empty(errors)
  end
end

class TestCreateTOC < Test::Unit::TestCase
  require 'nokogiri'
  ##
  # Tests TOC creation with sample document
  #
  def test_create_toc
    adoc_content = '= Test IDs

[#level_one]
== First 1

This is my first section.

[#level_two]
== Sign 2

Sign here please.

[#level_three]
=== My Section 3

Here is my very own section.
Thank you.

[#level_two_again]
== Another Sign 2

Sign here please.

[#level_three_again]
=== The Omen 3

Here is my very own section.
Thank you.

[[discrete_level_five_outlaw]]
[discrete]
===== Outlaw jumps to 5

The outlaw does not get caught because he is discrete

[[level_four]]
==== My Section 4

[#level_five]
===== Getting sectioned at 5

Sensing a pattern here?

[[level_six]]
====== 66 6

[#level_seven]
======= In too deep 7

[#level_nowhere]

[discrete]
=== Hide me senpai
'
    adoc = init(adoc_content, "#{self.class.name}_#{__method__}")
    ::Toolchain::ConfigManager.instance.load
    json_filepath, html_filepath, = ::Toolchain::Adoc::CreateTOC.new.run(adoc.parsed.catalog)
    
    # Test JSON file
    toc_object = JSON.parse(File.read(json_filepath))
    assert_equal('Getting sectioned at 5', toc_object['children'][2]['children'][0]['children'][0]['children'][0]['title'])
    
    # Test HTML file
    toc_html = Nokogiri::HTML.fragment(File.read(html_filepath))
    assert_equal('level_three.html', toc_html.css('div#toc > ul > li#toc_level_two > a + ul > li#toc_level_three > a').attribute('href').value)
    
    # Test hierarchy level attribute
    assert_equal('5', toc_html.css('li#toc_level_six').attribute('data-level').value)
  end
end
