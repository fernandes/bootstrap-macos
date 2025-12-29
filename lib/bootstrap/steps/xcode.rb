# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class Xcode < Step
      TOOLS_PATH = '/Library/Developer/CommandLineTools'

      def initialize(**args)
        super
        @poll_interval = 5
        @max_wait_time = 600
      end

      def name
        'Xcode Command Line Tools'
      end

      def installed?
        shell.directory_exists?(TOOLS_PATH)
      end

      def install!
        shell.run('xcode-select --install')
        wait_for_installation
      end

      private

      def wait_for_installation
        elapsed = 0
        until installed? || elapsed >= @max_wait_time
          sleep @poll_interval
          elapsed += @poll_interval
        end

        unless installed?
          raise 'Xcode CLI tools installation timed out or was cancelled'
        end
      end
    end
  end
end
