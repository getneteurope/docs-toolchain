# frozen_string_literal: true

module Toolchain
  ##
  # Foundation for all pre and post processing related steps.
  # {priority} will determine the order in which processes are run.
  class BaseProcess
    attr_accessor :priority

    def initialize(priority = 0)
      @priority = priority
    end

    def run
      raise NotImplementedError.new, "#{self.class.name}: no implementation for 'run'"
    end
  end
end
