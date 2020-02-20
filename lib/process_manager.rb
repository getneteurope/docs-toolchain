# frozen_string_literal: true

require 'singleton'

module Toolchain
  # Class ProcessManager
  # Used to register processes based on +BaseProcess+,
  # which run either before or after the build phase (pre or post).
  #
  # This class is an abstract class that is the base for +PreProcessManager+
  # and +PostProcessManager+.
  class ProcessManager
    include Singleton

    ##
    # Register a process +proc+ and sort the list of registered
    # processes by priority.
    #
    # Returns nothing.
    #
    def register(proc)
      @processes << proc
      @processes.sort_by!(&:priority).reverse!
      return nil
    end

    ##
    # Returns all registered processes as list.
    #
    def get
      return @processes
    end

    ##
    # Run all registered processes as separate threads.
    #
    def run
      @processes.each(&:run)
    end

    ##
    # Delete all registered processes.
    def clear
      @processes.clear
    end

    private

    def initialize
      @processes = []
    end
  end

  # Class representing the manager for all processes which
  # need to be run during the *Pre Processing* stage.
  class PreProcessManager < ProcessManager
  end

  # Class representing the manager for all processes which
  # need to be run during the *Post Processing* stage.
  class PostProcessManager < ProcessManager
  end
end
