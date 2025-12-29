# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class MenuBar < Step
      def name
        'Menu Bar Configuration'
      end

      def installed?
        spotlight_hidden?
      end

      def install!
        hide_spotlight
      end

      private

      def spotlight_hidden?
        result = shell.run('defaults -currentHost read com.apple.Spotlight MenuItemHidden')
        result.success? && result.output.strip == '1'
      end

      def hide_spotlight
        shell.run('defaults -currentHost write com.apple.Spotlight MenuItemHidden -bool true')
      end
    end
  end
end
