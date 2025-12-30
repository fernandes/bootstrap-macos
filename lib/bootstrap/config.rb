# frozen_string_literal: true

require 'yaml'

module Bootstrap
  class Config
    CONFIG_PATH = File.expand_path('../../config.yml', __dir__)
    GIST_ENV_VAR = 'BOOTSTRAP_CONFIG_URL'

    class << self
      def load
        @config ||= load_config
      end

      def load_from_hash(hash)
        @config = hash
      end

      def [](key)
        load.dig(*key.to_s.split('.'))
      end

      def fetch(key, default = nil)
        self[key] || default
      end

      def reset!
        @config = nil
      end

      private

      def load_config
        download_from_gist if should_download?

        unless File.exist?(CONFIG_PATH)
          raise "Config file not found at #{CONFIG_PATH}. " \
                "Create one from config.example.yml or set #{GIST_ENV_VAR} environment variable."
        end

        YAML.load_file(CONFIG_PATH)
      end

      def should_download?
        !File.exist?(CONFIG_PATH) && ENV[GIST_ENV_VAR]
      end

      def download_from_gist
        url = ENV[GIST_ENV_VAR]
        system("curl -sL '#{url}' -o '#{CONFIG_PATH}'")
      end
    end
  end
end
