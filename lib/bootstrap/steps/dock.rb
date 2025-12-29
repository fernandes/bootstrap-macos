# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class Dock < Step
      TILE_SIZE = 36
      PLIST_PATH = File.expand_path('~/Library/Preferences/com.apple.dock.plist')

      def name
        'Dock Configuration'
      end

      def installed?
        persistent_apps_empty? && tile_size_correct?
      end

      def install!
        clear_persistent_apps
        set_tile_size
        restart_dock
      end

      private

      def persistent_apps_empty?
        result = shell.run('defaults read com.apple.dock persistent-apps')
        return true unless result.success?

        # Empty array returns "()"
        result.output.strip == '(' + "\n" + ')'  || result.output.strip == '()'
      end

      def tile_size_correct?
        result = shell.run('defaults read com.apple.dock tilesize')
        return false unless result.success?

        result.output.strip.to_i == TILE_SIZE
      end

      def clear_persistent_apps
        shell.run('defaults write com.apple.dock persistent-apps -array')
      end

      def set_tile_size
        shell.run("defaults write com.apple.dock tilesize -int #{TILE_SIZE}")
      end

      def restart_dock
        shell.run('killall Dock')
      end
    end
  end
end
