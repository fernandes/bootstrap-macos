# frozen_string_literal: true

require_relative '../step'
require_relative '../config'
require 'fileutils'
require 'json'

module Bootstrap
  module Steps
    class Control < Step
      BREW_DEPS = %w[augeas pkgconf].freeze
      KEYS_ITEM_NAME = 'Control Repo'
      KEYS = %w[private_key.pkcs7.pem public_key.pkcs7.pem].freeze

      def name
        'Control Repo'
      end

      def installed?
        brew_deps_installed? &&
          repos_cloned? &&
          mise_tools_installed? &&
          bundle_installed? &&
          log_file_exists? &&
          keys_installed?
      end

      def brew_deps_installed?
        missing_brew_deps.empty?
      end

      def install!
        install_brew_deps
        ensure_config_directory
        clone_caco unless File.directory?(caco_path)
        clone_control unless File.directory?(control_path)
        install_mise_tools unless mise_tools_installed?
        run_bundle_install unless bundle_installed?
        create_log_file unless log_file_exists?
        fetch_keys unless keys_installed?
      end

      private

      # Brew dependencies
      def install_brew_deps
        missing = missing_brew_deps
        return if missing.empty?

        shell.run("brew install #{missing.join(' ')}")
      end

      def missing_brew_deps
        result = shell.run('brew list --formula')
        return BREW_DEPS unless result.success?

        installed = result.output.split("\n")
        BREW_DEPS.reject { |dep| installed.include?(dep) }
      end

      # Directories and repos
      def config_dir
        File.expand_path('~/config')
      end

      def control_path
        File.join(config_dir, 'control')
      end

      def caco_path
        File.join(config_dir, 'caco')
      end

      def keys_path
        File.join(control_path, 'keys')
      end

      def control_repo
        Config['control.repo']
      end

      def caco_repo
        Config.fetch('control.caco_repo', 'https://github.com/fernandes/caco')
      end

      def repos_cloned?
        File.directory?(control_path) && File.directory?(caco_path)
      end

      def ensure_config_directory
        FileUtils.mkdir_p(config_dir)
      end

      def clone_control
        result = shell.run("git clone #{control_repo} #{control_path}")
        raise "Failed to clone control repo: #{result.stderr}" unless result.success?
      end

      def clone_caco
        result = shell.run("git clone #{caco_repo} #{caco_path}")
        raise "Failed to clone caco repo: #{result.stderr}" unless result.success?
      end

      # Mise tools
      def mise_tools_installed?
        result = shell.run("cd #{control_path} && mise current")
        result.success? && !result.output.include?('not installed')
      end

      def install_mise_tools
        result = shell.run("cd #{control_path} && mise install")
        raise "Failed to install mise tools: #{result.stderr}" unless result.success?
      end

      # Bundle
      def bundle_installed?
        result = shell.run("cd #{control_path} && eval \"$(mise activate bash)\" && bundle check")
        result.success?
      end

      def run_bundle_install
        result = shell.run("cd #{control_path} && eval \"$(mise activate bash)\" && bundle install")
        raise "Failed to run bundle install: #{result.stderr}" unless result.success?
      end

      # Log file
      def log_file_path
        '/var/log/caco.log'
      end

      def log_file_exists?
        File.exist?(log_file_path)
      end

      def create_log_file
        current_user = ENV['USER']
        shell.run("sudo touch #{log_file_path}")
        result = shell.run("sudo chown #{current_user} #{log_file_path}")
        raise "Failed to create log file: #{result.stderr}" unless result.success?
      end

      # Bitwarden keys
      def keys_installed?
        KEYS.all? { |key| File.exist?(File.join(keys_path, key)) }
      end

      def fetch_keys
        FileUtils.mkdir_p(keys_path)
        session = unlock_vault
        sync_vault(session)
        fetch_keys_from_bitwarden(session)
      end

      def sync_vault(session)
        shell.run("bw sync --session '#{session}'")
      end

      def unlock_vault
        status_result = shell.run('bw status')
        status = JSON.parse(status_result.output) rescue {}

        if status['status'] == 'unauthenticated'
          output 'Bitwarden: Please login...'
          shell.run_interactive('bw login')
        end

        output 'Bitwarden: Please unlock vault...'
        unlock_result = shell.run_interactive_with_output('bw unlock --raw')
        unlock_result.output.strip
      end

      def fetch_keys_from_bitwarden(session)
        result = shell.run("bw get item '#{KEYS_ITEM_NAME}' --session '#{session}'")
        raise "Failed to get Control Repo from Bitwarden: #{result.stderr}" unless result.success?

        item = JSON.parse(result.output)
        item_id = item['id']

        KEYS.each do |key_name|
          destination = File.join(keys_path, key_name)
          download_attachment(session, item_id, key_name, destination)
        end
      end

      def download_attachment(session, item_id, attachment_name, destination)
        result = shell.run("bw get attachment '#{attachment_name}' --itemid '#{item_id}' --session '#{session}' --output '#{destination}'")
        raise "Failed to download #{attachment_name}: #{result.stderr}" unless result.success?
      end
    end
  end
end
