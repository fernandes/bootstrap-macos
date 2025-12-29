# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class Display < Step
      TARGET_RESOLUTION = '2304x1440'

      def name
        'Display Resolution'
      end

      def installed?
        displayplacer_installed? && current_resolution_matches?
      end

      def install!
        install_displayplacer unless displayplacer_installed?
        configure_resolution unless current_resolution_matches?
      end

      private

      def displayplacer_installed?
        shell.success?('which displayplacer')
      end

      def install_displayplacer
        result = shell.run('brew install displayplacer')
        unless result.success?
          raise "Failed to install displayplacer: #{result.stderr}"
        end
      end

      def current_resolution_matches?
        result = shell.run('displayplacer list')
        return false unless result.success?

        # Check the current resolution line, not the available modes
        match = result.output.match(/^Resolution:\s*(\d+x\d+)/m)
        match && match[1] == TARGET_RESOLUTION
      end

      def configure_resolution
        screen_id = detect_screen_id
        raise 'Could not detect screen ID' unless screen_id

        # Use mode number for more reliable setting
        mode = find_mode_for_resolution
        if mode
          result = shell.run(%(displayplacer "id:#{screen_id} mode:#{mode}"))
        else
          result = shell.run(%(displayplacer "id:#{screen_id} res:#{TARGET_RESOLUTION}"))
        end

        unless result.success?
          raise "Failed to set resolution: #{result.stderr}"
        end
      end

      def detect_screen_id
        result = shell.run('displayplacer list')
        return nil unless result.success?

        match = result.output.match(/Persistent screen id:\s*(\S+)/)
        match ? match[1] : nil
      end

      def find_mode_for_resolution
        result = shell.run('displayplacer list')
        return nil unless result.success?

        # Find mode with target resolution, prefer 59hz and color_depth:8
        match = result.output.match(/mode (\d+): res:#{TARGET_RESOLUTION} hz:59 color_depth:8\b/)
        match ? match[1] : nil
      end
    end
  end
end
