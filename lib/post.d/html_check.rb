# frozen_string_literal: true

require 'html-proofer'
require_relative '../base_process.rb'
require_relative '../utils/paths.rb'
require_relative '../log/log.rb'

module Toolchain
  ##
  # Adds modules for postprocessing files.
  module Post
    ##
    # Provides an interface to create a lunr search index
    # from the generated HTML files.
    class HTMLCheck < BaseProcess
      def initialize(priority = -10)
        super(priority)
      end

      def run(directory = ::Toolchain.html_path)
        ::HTMLProofer.check_directory(directory).run
      rescue RuntimeError => e
        stage_log(:post, "#{self.class.name} ran into errors")
        error(e.message)
      end
    end
  end
end

unless ENV.key?('FAST') || ENV.key?('SKIP_HTMLCHECK')
  Toolchain::PostProcessManager
    .instance.register(Toolchain::Post::HTMLCheck.new)
end
