# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class ModifierKeys < Step
      CAPS_LOCK = '0x700000039'
      LEFT_CONTROL = '0x7000000E0'

      PLIST_PATH = File.expand_path('~/Library/LaunchAgents/com.bootstrap.KeyRemapping.plist')
      PLIST_CONTENT = <<~PLIST
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>com.bootstrap.KeyRemapping</string>
          <key>ProgramArguments</key>
          <array>
            <string>/usr/bin/hidutil</string>
            <string>property</string>
            <string>--set</string>
            <string>{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":#{CAPS_LOCK},"HIDKeyboardModifierMappingDst":#{LEFT_CONTROL}},{"HIDKeyboardModifierMappingSrc":#{LEFT_CONTROL},"HIDKeyboardModifierMappingDst":#{CAPS_LOCK}}]}</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
        </dict>
        </plist>
      PLIST

      def name
        'Modifier Keys (Caps Lock <-> Control)'
      end

      def installed?
        shell.file_exists?(PLIST_PATH)
      end

      def install!
        apply_key_mapping
        create_launch_agent
      end

      private

      def apply_key_mapping
        json = %({"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":#{CAPS_LOCK},"HIDKeyboardModifierMappingDst":#{LEFT_CONTROL}},{"HIDKeyboardModifierMappingSrc":#{LEFT_CONTROL},"HIDKeyboardModifierMappingDst":#{CAPS_LOCK}}]})

        result = shell.run(%(hidutil property --set '#{json}'))
        unless result.success?
          raise "Failed to apply key mapping: #{result.stderr}"
        end
      end

      def create_launch_agent
        launch_agents_dir = File.dirname(PLIST_PATH)
        Dir.mkdir(launch_agents_dir) unless Dir.exist?(launch_agents_dir)

        File.write(PLIST_PATH, PLIST_CONTENT)
      end
    end
  end
end
