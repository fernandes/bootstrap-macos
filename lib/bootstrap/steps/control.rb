# frozen_string_literal: true

require_relative '../step'
require_relative '../config'
require 'fileutils'

module Bootstrap
  module Steps
    class Control < Step
      def name
        'Control Repo'
      end

      def installed?
        File.directory?(control_path) && File.directory?(caco_path)
      end

      def install!
        ensure_config_directory
        clone_caco unless File.directory?(caco_path)
        clone_control unless File.directory?(control_path)
      end

      private

      def config_dir
        File.expand_path('~/config')
      end

      def control_path
        File.join(config_dir, 'control')
      end

      def caco_path
        File.join(config_dir, 'caco')
      end

      def control_repo
        Config['control.repo']
      end

      def caco_repo
        Config.fetch('control.caco_repo', 'https://github.com/fernandes/caco')
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
    end
  end
end
