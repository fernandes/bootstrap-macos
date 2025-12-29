# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class Sound < Step
      ALERT_SOUND = '/System/Library/Sounds/Funk.aiff'
      ALERT_VOLUME = 0.1 # 10%

      def name
        'Sound Configuration'
      end

      def installed?
        alert_sound_correct? &&
          alert_volume_correct? &&
          startup_sound_disabled? &&
          ui_sounds_disabled?
      end

      def install!
        set_alert_sound
        set_alert_volume
        disable_startup_sound
        disable_ui_sounds
      end

      private

      def alert_sound_correct?
        result = shell.run('defaults read NSGlobalDomain com.apple.sound.beep.sound')
        result.success? && result.output.strip == ALERT_SOUND
      end

      def set_alert_sound
        shell.run("defaults write NSGlobalDomain com.apple.sound.beep.sound -string \"#{ALERT_SOUND}\"")
      end

      def alert_volume_correct?
        result = shell.run('defaults read NSGlobalDomain com.apple.sound.beep.volume')
        return false unless result.success?

        result.output.strip.to_f.round(1) == ALERT_VOLUME
      end

      def set_alert_volume
        shell.run("defaults write NSGlobalDomain com.apple.sound.beep.volume -float #{ALERT_VOLUME}")
      end

      def startup_sound_disabled?
        result = shell.run('nvram StartupMute 2>/dev/null')
        result.success? && result.output.include?('%01')
      end

      def disable_startup_sound
        shell.run('sudo nvram StartupMute=%01')
      end

      def ui_sounds_disabled?
        result = shell.run('defaults read NSGlobalDomain com.apple.sound.uiaudio.enabled')
        result.success? && result.output.strip == '0'
      end

      def disable_ui_sounds
        shell.run('defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -int 0')
      end
    end
  end
end
