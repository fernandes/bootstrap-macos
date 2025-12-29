# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class Homebrew < Step
      INSTALL_SCRIPT = 'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh'
      BREW_PATH_INTEL = '/usr/local/bin/brew'
      BREW_PATH_ARM = '/opt/homebrew/bin/brew'

      def name
        'Homebrew'
      end

      def installed?
        shell.file_exists?(BREW_PATH_INTEL) || shell.file_exists?(BREW_PATH_ARM)
      end

      def install!
        install_homebrew
        configure_shell
        disable_analytics
      end

      private

      def install_homebrew
        result = shell.run_interactive(%(/bin/bash -c "$(curl -fsSL #{INSTALL_SCRIPT})"))
        unless result.success?
          raise 'Failed to install Homebrew'
        end
      end

      def configure_shell
        brew_path = detect_brew_path
        zprofile = File.expand_path('~/.zprofile')

        shellenv_line = %(eval "$(#{brew_path} shellenv)")

        if shell.file_exists?(zprofile)
          content = File.read(zprofile)
          return if content.include?(shellenv_line)
        end

        File.open(zprofile, 'a') do |f|
          f.puts
          f.puts shellenv_line
        end

        shell.run(shellenv_line)
      end

      def disable_analytics
        brew_path = detect_brew_path
        shell.run("#{brew_path} analytics off")
      end

      def detect_brew_path
        if shell.file_exists?(BREW_PATH_ARM)
          BREW_PATH_ARM
        else
          BREW_PATH_INTEL
        end
      end
    end
  end
end
