# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require_relative './combine_js.rb'
require 'babel/transpiler'
# toolchain
require 'errors'

module Toolchain
  module Pre
    class TranspileJS < BaseProcess
      def run
        root = ::Toolchain.build_path
        js_files_glob = File.join(root, 'js', '*.js')
        Dir[js_files_glob].each do |js|
          js_code = File.open(js, 'r') { |f| f.read }
          transpiled = Babel::Transpiler.transform(js_code)['code']
          File.open(js, 'w') { |f| f.puts(transpiled) }
        end
      end
    end
  end
end


unless %w[FAST SKIP_JS SKIP_TRANSPILE].any? { |var| ENV.key?(var) }
  Toolchain::PreProcessManager.instance.register(
    Toolchain::Pre::TranspileJS.new(90))
end
