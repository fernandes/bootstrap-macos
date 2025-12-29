# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class Trackpad < Step
      def name
        'Trackpad Configuration'
      end

      def installed?
        secondary_click_correct? &&
          tap_to_click_enabled? &&
          app_expose_enabled?
      end

      def install!
        configure_secondary_click
        enable_tap_to_click
        enable_app_expose
        restart_dock
      end

      private

      def secondary_click_correct?
        result = shell.run('defaults read com.apple.AppleMultitouchTrackpad TrackpadRightClick')
        result.success? && result.output.strip == '1'
      end

      def configure_secondary_click
        # Enable two-finger click (Click with Two Fingers)
        shell.run('defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true')
        shell.run('defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 0')
        # Also set for bluetooth trackpad
        shell.run('defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true')
        shell.run('defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 0')
      end

      def tap_to_click_enabled?
        result = shell.run('defaults read com.apple.AppleMultitouchTrackpad Clicking')
        result.success? && result.output.strip == '1'
      end

      def enable_tap_to_click
        shell.run('defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true')
        shell.run('defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true')
        # Enable for login screen as well
        shell.run('defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1')
      end

      def app_expose_enabled?
        result = shell.run('defaults read com.apple.dock showAppExposeGestureEnabled')
        result.success? && result.output.strip == '1'
      end

      def enable_app_expose
        # Enable App Expose gesture (swipe down with three fingers)
        shell.run('defaults write com.apple.dock showAppExposeGestureEnabled -bool true')
        # Set three finger swipe for App Expose (value 2 = App Expose)
        shell.run('defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 2')
        shell.run('defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture -int 2')
      end

      def restart_dock
        shell.run('killall Dock')
      end
    end
  end
end
