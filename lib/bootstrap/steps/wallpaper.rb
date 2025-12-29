# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class Wallpaper < Step
      WALLPAPER_PATH = '/System/Library/Desktop Pictures/Solid Colors/Blue Violet.png'

      def name
        'Wallpaper Configuration'
      end

      def installed?
        current_wallpaper == WALLPAPER_PATH
      end

      def install!
        set_wallpaper
      end

      private

      def current_wallpaper
        result = shell.run("osascript -e 'tell application \"System Events\" to get picture of desktop 1'")
        return nil unless result.success?

        result.output.strip
      end

      def set_wallpaper
        shell.run("osascript -e 'tell application \"System Events\" to tell every desktop to set picture to \"#{WALLPAPER_PATH}\"'")
      end
    end
  end
end
