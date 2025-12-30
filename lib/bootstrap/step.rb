# frozen_string_literal: true

module Bootstrap
  class Step
    attr_reader :shell

    class << self
      attr_accessor :silent
    end

    def initialize(shell: Shell)
      @shell = shell
    end

    def output(message)
      puts message unless Bootstrap::Step.silent
    end

    def name
      self.class.name.split('::').last
    end

    def installed?
      raise NotImplementedError, "#{self.class} must implement #installed?"
    end

    def install!
      raise NotImplementedError, "#{self.class} must implement #install!"
    end

    def run!
      if installed?
        { status: :skipped, message: "#{name} already installed" }
      else
        install!
        { status: :installed, message: "#{name} installed successfully" }
      end
    end
  end
end
