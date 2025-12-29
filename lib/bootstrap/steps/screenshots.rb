# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class Screenshots < Step
      LOCATION = File.expand_path('~/Screenshots')

      def name
        'Screenshots Configuration'
      end

      def installed?
        shadow_disabled? && location_correct?
      end

      def install!
        create_screenshots_directory
        disable_shadow
        set_location
        restart_ui
      end

      private

      def shadow_disabled?
        result = shell.run('defaults read com.apple.screencapture disable-shadow')
        result.success? && result.output.strip == '1'
      end

      def location_correct?
        result = shell.run('defaults read com.apple.screencapture location')
        result.success? && result.output.strip == LOCATION
      end

      def create_screenshots_directory
        Dir.mkdir(LOCATION) unless Dir.exist?(LOCATION)
      end

      def disable_shadow
        shell.run('defaults write com.apple.screencapture disable-shadow -bool true')
      end

      def set_location
        shell.run("defaults write com.apple.screencapture location -string \"#{LOCATION}\"")
      end

      def restart_ui
        shell.run('killall SystemUIServer')
      end
    end
  end
end
