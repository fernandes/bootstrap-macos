# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class Dock < Step
      TILE_SIZE = 36
      # Minimize effect: genie, scale, suck
      MINIMIZE_EFFECT = 'scale'

      def name
        'Dock Configuration'
      end

      def installed?
        persistent_apps_empty? &&
          tile_size_correct? &&
          minimize_effect_correct? &&
          recents_hidden? &&
          process_indicators_hidden? &&
          window_animations_disabled?
      end

      def install!
        clear_persistent_apps
        set_tile_size
        set_minimize_effect
        hide_recents
        hide_process_indicators
        disable_window_animations
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

      def minimize_effect_correct?
        result = shell.run('defaults read com.apple.dock mineffect')
        result.success? && result.output.strip == MINIMIZE_EFFECT
      end

      def set_minimize_effect
        shell.run("defaults write com.apple.dock mineffect -string \"#{MINIMIZE_EFFECT}\"")
      end

      def recents_hidden?
        result = shell.run('defaults read com.apple.dock show-recents')
        result.success? && result.output.strip == '0'
      end

      def hide_recents
        shell.run('defaults write com.apple.dock show-recents -bool false')
      end

      def process_indicators_hidden?
        result = shell.run('defaults read com.apple.dock show-process-indicators')
        result.success? && result.output.strip == '0'
      end

      def hide_process_indicators
        shell.run('defaults write com.apple.dock show-process-indicators -bool false')
      end

      def window_animations_disabled?
        result = shell.run('defaults read NSGlobalDomain NSAutomaticWindowAnimationsEnabled')
        result.success? && result.output.strip == '0'
      end

      def disable_window_animations
        shell.run('defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false')
      end

      def restart_dock
        shell.run('killall Dock')
      end
    end
  end
end
