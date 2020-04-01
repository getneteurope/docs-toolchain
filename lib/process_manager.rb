# frozen_string_literal: true

require 'singleton'
require_relative './config_manager.rb'

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
      # extract ClassName from Toolchain::Extension::ClassName
      name = proc.class.name.split('::').last
      load = ::Toolchain::ConfigManager.instance
        .contains?("processes.#{@phase}.enable", name)
      if load
        @processes << proc
        @processes.sort_by!(&:priority).reverse!
      else
        log('CONFIG', "skipping #{name}: not found in config", :yellow)
      end
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
      return @code
    end

    ##
    # Delete all registered processes.
    def clear
      @processes.clear
    end

    ##
    # Set the return code `@code` to non-zero value `error_code`.
    # This means the stage failed.
    def return_code(error_code = 10)
      @code = error_code
    end

    private

    def initialize(phase = nil)
      @processes = []
      @code = 0
      @phase = phase
    end
  end

  # Class representing the manager for all processes which
  # need to be run during the *Pre Processing* stage.
  class PreProcessManager < ProcessManager
    private

    def initialize
      super('pre')
    end
  end

  # Class representing the manager for all processes which
  # need to be run during the *Post Processing* stage.
  class PostProcessManager < ProcessManager
    private

    def initialize
      super('post')
    end
  end
end
