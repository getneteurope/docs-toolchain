# frozen_string_literal: true

require_relative '../process_manager.rb'
require_relative '../base_process.rb'
require_relative '../log/log.rb'
require 'babel/transpiler'
# toolchain
require 'errors'

module Toolchain
  module Pre
    ##
    # Babel wrapper class for PreProcessing
    #
    class TranspileJS < BaseProcess
      ##
      # Transpile all JS files using Babel.
      # Ignore the path +js/vendor/+
      #
      def run
        stage_log('pre', '[TranspileJS] -> running')
        root = ::Toolchain.build_path
        js_files_glob = File.join(root, 'js', '*.js')
        Dir[js_files_glob].each do |js|
          js_code = File.read(js)
          transpiled = Babel::Transpiler.transform(js_code)['code']
          stage_log('pre', '[TranspileJS] -> Transpiling ' + js)
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
