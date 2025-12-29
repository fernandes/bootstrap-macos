# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/activity_monitor'

class ActivityMonitorTest < Minitest::Test
  class MockShell
    attr_accessor :commands_run, :run_results

    def initialize
      @commands_run = []
      @run_results = {}
    end

    def run(command)
      @commands_run << command
      @run_results[command] || Struct.new(:success?, :stderr, :output).new(true, '', '')
    end
  end

  def setup
    @shell = MockShell.new
    @step = Bootstrap::Steps::ActivityMonitor.new(shell: @shell)
  end

  def test_name
    assert_equal 'Activity Monitor Configuration', @step.name
  end

  def test_installed_returns_false_when_update_period_wrong
    @shell.run_results['defaults read com.apple.ActivityMonitor UpdatePeriod'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '5')

    refute @step.installed?
  end

  def test_installed_returns_true_when_configured
    @shell.run_results['defaults read com.apple.ActivityMonitor UpdatePeriod'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '2')

    assert @step.installed?
  end

  def test_install_sets_update_period
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.ActivityMonitor UpdatePeriod -int 2'
  end

  def test_run_skips_when_already_configured
    @shell.run_results['defaults read com.apple.ActivityMonitor UpdatePeriod'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '2')

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
