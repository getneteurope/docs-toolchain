# frozen_string_literal: true

require 'test/unit'
require 'nokogiri'
require 'asciidoctor'
require_relative './util.rb'
require_relative '../lib/utils/create_toc.rb'
require_relative '../lib/utils/hash.rb'

##
# Tests TOC creation with sample document
#
class TestCreateTOC < Test::Unit::TestCase
  CONTENT = '= Test IDs

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

  def test_create_toc
    adoc = init(CONTENT, "#{self.class.name}_#{__method__}")
    ::Toolchain::ConfigManager.instance.load
    json_filepath, html_filepath, = ::Toolchain::Adoc::CreateTOC.new.run(adoc.parsed)

    # Test JSON file
    toc_object = JSON.parse(File.read(json_filepath))
    assert_equal('Getting sectioned at 5',
      toc_object['children'][2]['children'][0]['children'][0]['children'][0]['title'])

    # Test HTML file
    toc_document = Nokogiri::HTML.fragment(File.read(html_filepath))
    href = toc_document.css(
      'div#toc > ul > li#toc_li_level_two > input + label > a'
    ).attribute('href').value

    assert_equal('level_two.html', href)

    # Test hierarchy level attribute
    assert_equal('5', toc_document.css('li#toc_li_level_six').attribute('data-level').value)

    # Test if checkboxes are correctly ticked for a given page
    ticked_toc = ::Toolchain::Adoc::CreateTOC.new.tick_toc_checkboxes('level_three_again', toc_document)
    assert_nil(toc_document.at_css('#toc_cb_level_three').attributes['checked'])
    assert_not_nil(toc_document.at_css('#toc_cb_level_three_again').attributes['checked'])
    assert_not_nil(toc_document.at_css('#toc_cb_level_two_again').attributes['checked'])
  end

  def test_create_toc_fail_silently
    adoc = init(CONTENT, "#{self.class.name}_#{__method__}")
    ::Toolchain::ConfigManager.instance.load
    json_filepath, html_filepath, = ::Toolchain::Adoc::CreateTOC.new.run(adoc.parsed)


    # Test HTML file
    toc_document = Nokogiri::HTML.fragment(File.read(html_filepath))
    toc_original = toc_document.dup
    # removing the input tag under li will force an exception in tick_toc_checkboxes
    elem = toc_document.css('li#toc_li_level_five > input')
    elem.remove

    # Test if exceptions are caught and the methods fails silently
    assert_nothing_raised(StandardError) do
      ticked_toc = ::Toolchain::Adoc::CreateTOC.new
        .tick_toc_checkboxes('level_six', toc_document)
    end
  end
end
