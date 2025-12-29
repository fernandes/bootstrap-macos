# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/keyboard'

class KeyboardTest < Minitest::Test
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
    @step = Bootstrap::Steps::Keyboard.new(shell: @shell)
  end

  def setup_all_configured
    @shell.run_results['defaults read NSGlobalDomain KeyRepeat'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read NSGlobalDomain InitialKeyRepeat'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '10')
    @shell.run_results['defaults read com.apple.HIToolbox AppleFnUsageType'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '2')
    @shell.run_results['defaults read NSGlobalDomain AppleKeyboardUIMode'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '2')
    @shell.run_results['defaults read NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '0')
  end

  def test_name
    assert_equal 'Keyboard Configuration', @step.name
  end

  def test_installed_returns_false_when_key_repeat_wrong
    @shell.run_results['defaults read NSGlobalDomain KeyRepeat'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '6')

    refute @step.installed?
  end

  def test_installed_returns_true_when_configured
    setup_all_configured
    assert @step.installed?
  end

  def test_install_sets_key_repeat
    @step.install!
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain KeyRepeat -int 1'
  end

  def test_install_sets_initial_key_repeat
    @step.install!
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain InitialKeyRepeat -int 10'
  end

  def test_install_sets_fn_key_usage
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.HIToolbox AppleFnUsageType -int 2'
  end

  def test_install_enables_keyboard_navigation
    @step.install!
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain AppleKeyboardUIMode -int 2'
  end

  def test_install_disables_auto_punctuation
    @step.install!
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false'
  end

  def test_install_configures_dictation_shortcut
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMShortcut -int 3'
  end

  def test_run_skips_when_already_configured
    setup_all_configured

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
