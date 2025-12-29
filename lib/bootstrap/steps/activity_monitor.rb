# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class ActivityMonitor < Step
      # Update frequency in seconds: 1 (very often), 2 (often), 5 (normally)
      UPDATE_PERIOD = 2

      def name
        'Activity Monitor Configuration'
      end

      def installed?
        update_period_correct?
      end

      def install!
        set_update_period
      end

      private

      def update_period_correct?
        result = shell.run('defaults read com.apple.ActivityMonitor UpdatePeriod')
        result.success? && result.output.strip.to_i == UPDATE_PERIOD
      end

      def set_update_period
        shell.run("defaults write com.apple.ActivityMonitor UpdatePeriod -int #{UPDATE_PERIOD}")
      end
    end
  end
end
