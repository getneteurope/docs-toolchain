# frozen_string_literal: true

require 'html-proofer'
require 'os'
require_relative '../base_process.rb'
require_relative '../utils/paths.rb'
require_relative '../log/log.rb'

module Toolchain
  ##
  # Adds modules for postprocessing files.
  module Post
    ##
    # Post process that runs HTML Proofer on the generated HTML documents.
    class HTMLProofer < BaseProcess
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

    ##
    # Post process that runs HTML Proofer on the generated HTML documents.
    class HTMLTest < BaseProcess
      def initialize(priority = -10)
        super(priority)
        @bin_dir = ::File.join(::Toolchain.toolchain_path, 'bin', 'ext')
        @version = '0.12.1'
        @arch = 'amd64'
      end

      def run(directory = ::Toolchain.html_path)
        os = nil
        os = 'linux' if OS.linux?
        os = 'windows' if OS.windows?
        os = 'osx' if OS.mac?
        bin = ::File.join(
          @bin_dir,
          "htmltest_#{@version}_#{os}_#{@arch}",
          (os == 'windows' ? 'htmltest.exe' : 'htmltest')
        )
        unless os.nil? || OS.bits != 64
          stage_log(:post, "Running htmltest #{@version} as #{os}")
          unless system("#{bin} #{directory}") # returns false if failed
            ::Toolchain::PostProcessManager.instance.return_code
          end
        end
      end
    end
  end
end

unless ENV.key?('FAST') || ENV.key?('SKIP_HTMLCHECK')
  Toolchain::PostProcessManager .instance.register(
    Toolchain::Post::HTMLTest.new)
  #   Toolchain::PostProcessManager
  #     .instance.register(Toolchain::Post::HTMLCheck.new)
end
