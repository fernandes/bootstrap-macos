# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class Safari < Step
      def name
        'Safari Configuration'
      end

      def installed?
        show_full_url?
      end

      def install!
        configure_full_url
      end

      private

      def show_full_url?
        result = shell.run('defaults read com.apple.Safari ShowFullURLInSmartSearchField')
        result.success? && result.output.strip == '1'
      end

      def configure_full_url
        shell.run('defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true')
      end
    end
  end
end
