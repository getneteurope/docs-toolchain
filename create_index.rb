require_relative './lib/pre.d/compile_search_index.rb'

Toolchain::Pre::CompileSearchIndex.new.run('../content/index.adoc')

Toolchain::Pre::CompileSearchIndex.new.run()
