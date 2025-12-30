# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class Mise < Step
      def name
        'Mise'
      end

      ZSHRC_LINE = 'eval "$(mise activate zsh)"'

      def installed?
        cli_installed? && ruby_version_file_enabled? && zsh_activated?
      end

      RUBY_BUILD_DEPS = %w[openssl@3 readline libyaml gmp autoconf].freeze

      def install!
        install_ruby_build_deps
        install_cli unless cli_installed?
        configure_ruby_version_file
        activate_in_zsh unless zsh_activated?
      end

      private

      def install_ruby_build_deps
        missing = missing_ruby_build_deps
        return if missing.empty?

        shell.run("brew install #{missing.join(' ')}")
      end

      def missing_ruby_build_deps
        result = shell.run('brew list --formula')
        return RUBY_BUILD_DEPS unless result.success?

        installed = result.output.split("\n")
        RUBY_BUILD_DEPS.reject { |dep| installed.include?(dep) }
      end

      def cli_installed?
        result = shell.run('which mise')
        result.success? && !result.output.strip.empty?
      end

      def install_cli
        shell.run('brew install mise')
      end

      def ruby_version_file_enabled?
        result = shell.run('mise settings get idiomatic_version_file_enable_tools')
        result.success? && result.output.include?('ruby')
      end

      def configure_ruby_version_file
        shell.run('mise settings add idiomatic_version_file_enable_tools ruby')
      end

      def zshrc_path
        File.expand_path('~/.zshrc')
      end

      def zsh_activated?
        return false unless File.exist?(zshrc_path)

        File.read(zshrc_path).include?(ZSHRC_LINE)
      end

      def activate_in_zsh
        File.open(zshrc_path, 'a') do |f|
          f.puts "\n# Mise"
          f.puts ZSHRC_LINE
        end
      end
    end
  end
end
