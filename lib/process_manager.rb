# frozen_string_literal: true

require 'singleton'

module Toolchain
  class ProcessManager
    include Singleton

    def register(proc)
      @processes << proc
      @processes.sort_by!(&:priority).reverse!
    end

    def get
      return @processes
    end

    def run
      threads = []
      @processes.each do |proc|
        threads << Thread.new { proc.run }
      end
      threads.map(&:join)
    end

    def clear
      @processes.clear
    end

    private

    def initialize
      @processes = []
    end
  end

  class PreProcessManager < ProcessManager
  end

  class PostProcessManager < ProcessManager
  end
end
