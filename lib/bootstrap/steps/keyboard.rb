# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class Keyboard < Step
      # KeyRepeat: lower = faster, 1 = fastest
      KEY_REPEAT = 1
      # InitialKeyRepeat: lower = shorter delay, 10 = very short (1 before fastest)
      INITIAL_KEY_REPEAT = 10
      # AppleFnUsageType: 0 = Do Nothing, 1 = Change Input Source, 2 = Show Emoji & Symbols, 3 = Start Dictation
      FN_KEY_USAGE = 2

      def name
        'Keyboard Configuration'
      end

      def installed?
        key_repeat_correct? &&
          initial_key_repeat_correct? &&
          fn_key_usage_correct? &&
          keyboard_navigation_enabled? &&
          auto_punctuation_disabled?
      end

      def install!
        set_key_repeat
        set_initial_key_repeat
        set_fn_key_usage
        enable_keyboard_navigation
        disable_auto_punctuation
        configure_dictation_shortcut
      end

      private

      def key_repeat_correct?
        result = shell.run('defaults read NSGlobalDomain KeyRepeat')
        result.success? && result.output.strip.to_i == KEY_REPEAT
      end

      def set_key_repeat
        shell.run("defaults write NSGlobalDomain KeyRepeat -int #{KEY_REPEAT}")
      end

      def initial_key_repeat_correct?
        result = shell.run('defaults read NSGlobalDomain InitialKeyRepeat')
        result.success? && result.output.strip.to_i == INITIAL_KEY_REPEAT
      end

      def set_initial_key_repeat
        shell.run("defaults write NSGlobalDomain InitialKeyRepeat -int #{INITIAL_KEY_REPEAT}")
      end

      def fn_key_usage_correct?
        result = shell.run('defaults read com.apple.HIToolbox AppleFnUsageType')
        result.success? && result.output.strip.to_i == FN_KEY_USAGE
      end

      def set_fn_key_usage
        shell.run("defaults write com.apple.HIToolbox AppleFnUsageType -int #{FN_KEY_USAGE}")
      end

      def keyboard_navigation_enabled?
        result = shell.run('defaults read NSGlobalDomain AppleKeyboardUIMode')
        result.success? && result.output.strip.to_i == 2
      end

      def enable_keyboard_navigation
        shell.run('defaults write NSGlobalDomain AppleKeyboardUIMode -int 2')
      end

      def auto_punctuation_disabled?
        result = shell.run('defaults read NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled')
        result.success? && result.output.strip == '0'
      end

      def disable_auto_punctuation
        shell.run('defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false')
      end

      def configure_dictation_shortcut
        # Dictation shortcut: 3 = Press Right Command Twice
        shell.run('defaults write com.apple.HIToolbox AppleDictationAutoEnable -int 1')
        shell.run('defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMShortcut -int 3')
      end
    end
  end
end
