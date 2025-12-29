# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/sound'

class SoundTest < Minitest::Test
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
    @step = Bootstrap::Steps::Sound.new(shell: @shell)
  end

  def setup_all_configured
    @shell.run_results['defaults read NSGlobalDomain com.apple.sound.beep.sound'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/System/Library/Sounds/Funk.aiff')
    @shell.run_results['defaults read NSGlobalDomain com.apple.sound.beep.volume'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '0.1')
    @shell.run_results['nvram StartupMute 2>/dev/null'] =
      Struct.new(:success?, :stderr, :output).new(true, '', 'StartupMute	%01')
    @shell.run_results['defaults read NSGlobalDomain com.apple.sound.uiaudio.enabled'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '0')
  end

  def test_name
    assert_equal 'Sound Configuration', @step.name
  end

  def test_installed_returns_false_when_alert_sound_wrong
    @shell.run_results['defaults read NSGlobalDomain com.apple.sound.beep.sound'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/System/Library/Sounds/Basso.aiff')

    refute @step.installed?
  end

  def test_installed_returns_true_when_configured
    setup_all_configured
    assert @step.installed?
  end

  def test_install_sets_alert_sound
    @step.install!
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain com.apple.sound.beep.sound -string "/System/Library/Sounds/Funk.aiff"'
  end

  def test_install_sets_alert_volume
    @step.install!
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain com.apple.sound.beep.volume -float 0.1'
  end

  def test_install_disables_startup_sound
    @step.install!
    assert_includes @shell.commands_run, 'sudo nvram StartupMute=%01'
  end

  def test_install_disables_ui_sounds
    @step.install!
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -int 0'
  end

  def test_run_skips_when_already_configured
    setup_all_configured

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
