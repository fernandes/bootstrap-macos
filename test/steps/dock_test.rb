# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/dock'

class DockTest < Minitest::Test
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
    @step = Bootstrap::Steps::Dock.new(shell: @shell)
  end

  def test_name
    assert_equal 'Dock Configuration', @step.name
  end

  def test_installed_returns_false_when_persistent_apps_not_empty
    @shell.run_results['defaults read com.apple.dock persistent-apps'] =
      Struct.new(:success?, :stderr, :output).new(true, '', "(\n    { some = app; }\n)")
    @shell.run_results['defaults read com.apple.dock tilesize'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '36')

    refute @step.installed?
  end

  def test_installed_returns_false_when_tile_size_wrong
    @shell.run_results['defaults read com.apple.dock persistent-apps'] =
      Struct.new(:success?, :stderr, :output).new(true, '', "()")
    @shell.run_results['defaults read com.apple.dock tilesize'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '64')

    refute @step.installed?
  end

  def test_installed_returns_true_when_configured
    @shell.run_results['defaults read com.apple.dock persistent-apps'] =
      Struct.new(:success?, :stderr, :output).new(true, '', "()")
    @shell.run_results['defaults read com.apple.dock tilesize'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '36')

    assert @step.installed?
  end

  def test_install_clears_persistent_apps
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.dock persistent-apps -array'
  end

  def test_install_sets_tile_size
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.dock tilesize -int 36'
  end

  def test_install_restarts_dock
    @step.install!
    assert_includes @shell.commands_run, 'killall Dock'
  end

  def test_run_skips_when_already_configured
    @shell.run_results['defaults read com.apple.dock persistent-apps'] =
      Struct.new(:success?, :stderr, :output).new(true, '', "()")
    @shell.run_results['defaults read com.apple.dock tilesize'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '36')

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
