# frozen_string_literal: true

require_relative '../step'
require_relative '../config'
require 'json'
require 'fileutils'

module Bootstrap
  module Steps
    class SshKey < Step
      def name
        'SSH Key'
      end

      def installed?
        File.exist?(private_key_path)
      end

      def install!
        ensure_ssh_directory
        session = unlock_vault
        fetch_and_save_keys(session)
        set_permissions
      end

      private

      def ssh_dir
        File.expand_path('~/.ssh')
      end

      def key_name
        Config.fetch('ssh.key_name', 'id_ed25519')
      end

      def private_key_path
        File.join(ssh_dir, key_name)
      end

      def public_key_path
        "#{private_key_path}.pub"
      end

      def ssh_item_name
        Config['bitwarden.ssh_item']
      end

      def ensure_ssh_directory
        FileUtils.mkdir_p(ssh_dir)
        File.chmod(0o700, ssh_dir)
      end

      def unlock_vault
        # Check if already logged in
        status_result = shell.run('bw status')
        status = JSON.parse(status_result.output) rescue {}

        if status['status'] == 'unauthenticated'
          puts 'Bitwarden: Please login...'
          shell.run_interactive('bw login')
        end

        # Unlock and get session
        puts 'Bitwarden: Please unlock vault...'
        unlock_result = shell.run_interactive_with_output('bw unlock --raw')
        unlock_result.output.strip
      end

      def fetch_and_save_keys(session)
        # Get item ID first
        result = shell.run("bw get item '#{ssh_item_name}' --session '#{session}'")
        raise "Failed to get SSH key from Bitwarden: #{result.stderr}" unless result.success?

        item = JSON.parse(result.output)
        item_id = item['id']

        # Download attachments
        download_attachment(session, item_id, key_name, private_key_path)
        download_attachment(session, item_id, "#{key_name}.pub", public_key_path)
      end

      def download_attachment(session, item_id, attachment_name, destination)
        result = shell.run("bw get attachment '#{attachment_name}' --itemid '#{item_id}' --session '#{session}' --output '#{destination}'")
        raise "Failed to download #{attachment_name}: #{result.stderr}" unless result.success?
      end

      def set_permissions
        File.chmod(0o600, private_key_path)
        File.chmod(0o644, public_key_path) if File.exist?(public_key_path)
      end
    end
  end
end
