# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/screenshots'
require 'fileutils'

class ScreenshotsTest < Minitest::Test
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
    @step = Bootstrap::Steps::Screenshots.new(shell: @shell)
  end

  def test_name
    assert_equal 'Screenshots Configuration', @step.name
  end

  def test_installed_returns_false_when_shadow_enabled
    @shell.run_results['defaults read com.apple.screencapture disable-shadow'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '0')

    refute @step.installed?
  end

  def test_installed_returns_true_when_configured
    @shell.run_results['defaults read com.apple.screencapture disable-shadow'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read com.apple.screencapture location'] =
      Struct.new(:success?, :stderr, :output).new(true, '', File.expand_path('~/Screenshots'))

    assert @step.installed?
  end

  def test_install_disables_shadow
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.screencapture disable-shadow -bool true'
  end

  def test_install_sets_location
    @step.install!
    assert @shell.commands_run.any? { |cmd| cmd.include?('defaults write com.apple.screencapture location') }
  end

  def test_install_restarts_ui
    @step.install!
    assert_includes @shell.commands_run, 'killall SystemUIServer'
  end
end
