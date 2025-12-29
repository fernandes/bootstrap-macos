# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class ClaudeCode < Step
      CASK_NAME = 'claude-code'

      def name
        'Claude Code'
      end

      def installed?
        result = shell.run("brew list --cask #{CASK_NAME} 2>/dev/null")
        result.success?
      end

      def install!
        result = shell.run("brew install --cask #{CASK_NAME}")
        unless result.success?
          raise "Failed to install Claude Code: #{result.stderr}"
        end
      end
    end
  end
end
