# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/trackpad'

class TrackpadTest < Minitest::Test
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
    @step = Bootstrap::Steps::Trackpad.new(shell: @shell)
  end

  def setup_all_configured
    @shell.run_results['defaults read com.apple.AppleMultitouchTrackpad TrackpadRightClick'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read com.apple.AppleMultitouchTrackpad Clicking'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read com.apple.dock showAppExposeGestureEnabled'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
  end

  def test_name
    assert_equal 'Trackpad Configuration', @step.name
  end

  def test_installed_returns_false_when_secondary_click_wrong
    @shell.run_results['defaults read com.apple.AppleMultitouchTrackpad TrackpadRightClick'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '0')

    refute @step.installed?
  end

  def test_installed_returns_true_when_configured
    setup_all_configured
    assert @step.installed?
  end

  def test_install_configures_secondary_click
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true'
  end

  def test_install_enables_tap_to_click
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true'
  end

  def test_install_enables_app_expose
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.dock showAppExposeGestureEnabled -bool true'
  end

  def test_install_restarts_dock
    @step.install!
    assert_includes @shell.commands_run, 'killall Dock'
  end

  def test_run_skips_when_already_configured
    setup_all_configured

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
