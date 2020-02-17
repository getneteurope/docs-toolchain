# frozen_string_literal: true

require_relative './utils/paths.rb'

module Toolchain
  ##
  # Foundation for all pre and post processing related steps.
  # The field {priority} will determine the order in which processes are run.
  class BaseProcess
    # Describes the order in which processes are executed.
    attr_reader :priority

    ##
    # Create a new Process object with +priority+ (default: 0).
    #
    # +priority+ determines the order in which processes are run.
    # A higher priority means it will run first.
    #
    # @example
    #     ProcessManager.register(Process.new(10))
    #     ProcessManager.register(Process.new(100)) # would run first
    #     ProcessManager.run() # First process with priority 100, then 10
    #
    # Returns a new process object with +priority+.
    #
    def initialize(priority = 0)
      @priority = priority
    end

    ##
    # Runs the process.
    # Takes no arguments.
    #
    # Returns nothing, but throws an exception if not implemented
    # in the subclass.
    #
    def run
      raise NotImplementedError.new,
        "#{self.class.name}: no implementation for 'run'"
    end
  end
end
