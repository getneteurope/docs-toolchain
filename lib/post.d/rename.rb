# frozen_string_literal: true

require_relative '../base_process.rb'
require_relative '../process_manager.rb'
require_relative '../utils/paths.rb'
require_relative '../log/log.rb'

module Toolchain
  ##
  # Adds modules for postprocessing files.
  module Post
    ##
    # Duplicates the file Home.html to index.html, in order the have a correct startpage.
    #
    class Rename < BaseProcess
      def run
        stage_log(:post, 'Copying Home.html to index.html')
        ::FileUtils.cp(
          ::File.join(::Toolchain.html_path, 'Home.html'),
          ::File.join(::Toolchain.html_path, 'index.html')
        )
      end
    end
  end
end

Toolchain::PostProcessManager.instance.register(Toolchain::Post::Rename.new)
