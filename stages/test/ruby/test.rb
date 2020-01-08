# frozen_string_literal: true

require 'asciidoctor'
require_relative './modules.d/link_checker'

adoc = '= Test links

1. https://github.com/wirecard/docs-toolchain[Docs Toolchain]
2. https://github.com/asciidoctor/asciidoctor-exteansions-lab[Asciidoctor Extensions Lab]
3. https://adfasdgea.asd/adfadfasdf/[Unknown Domain]
4. http://111.222.123.48[Random IP]
'

document = Asciidoctor.load(adoc)
document.convert
puts adoc
puts document
puts Toolchain::LinkChecker.new.run(document)
