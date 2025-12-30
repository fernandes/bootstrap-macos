# frozen_string_literal: true

require_relative '../step'
require_relative '../config'

module Bootstrap
  module Steps
    class Bitwarden < Step
      def name
        'Bitwarden CLI'
      end

      def installed?
        cli_installed? && server_configured?
      end

      def install!
        install_cli unless cli_installed?
        configure_server
      end

      private

      def server_url
        Config['bitwarden.server']
      end

      def cli_installed?
        result = shell.run('which bw')
        result.success? && !result.output.strip.empty?
      end

      def install_cli
        shell.run('brew install bitwarden-cli')
      end

      def server_configured?
        result = shell.run('bw config server')
        result.success? && result.output.strip == server_url
      end

      def configure_server
        shell.run("bw config server #{server_url}")
      end
    end
  end
end
