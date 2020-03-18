# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../utils/paths.rb'
require_relative '../log/log.rb'

module Toolchain
  ##
  # Adds modules for postprocessing files.
  module Post
    ##
    # Copies the CodeRay style defined in `content/css/asciidoctor-coderay.css`
    # to the build dir.
    #
    # NOTE This is a fix to mitigate an issue with asciidoctor and coderay,
    # where the coderay style file is always written to disk,
    # even if one already exsits (i.e. overwriting the style).
    #
    class CodeRayStyleCopy < BaseProcess
      def run
        coderay_css = 'asciidoctor-coderay.css'
        stage_log(:post, "Copying CodeRay stylesheet to HTML directory: #{coderay_css}")
        ::FileUtils.cp(
          ::File.join(::Toolchain.document_root, 'css', coderay_css),
          ::File.join(::Toolchain.html_path, 'css', coderay_css)
        )
      end
    end
  end
end

Toolchain::PostProcessManager.instance.register(Toolchain::Post::CodeRayStyleCopy.new)
