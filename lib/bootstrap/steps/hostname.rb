# frozen_string_literal: true

require_relative '../step'
require_relative '../config'

module Bootstrap
  module Steps
    class Hostname < Step
      def name
        'Hostname'
      end

      def installed?
        current_hostname == desired_hostname
      end

      def install!
        shell.run("sudo scutil --set ComputerName #{desired_hostname}")
        shell.run("sudo scutil --set HostName #{desired_hostname}")
        shell.run("sudo scutil --set LocalHostName #{desired_hostname}")
      end

      private

      def desired_hostname
        Config['mac.hostname']
      end

      def current_hostname
        result = shell.run('scutil --get ComputerName')
        result.success? ? result.output.strip : nil
      end
    end
  end
end
