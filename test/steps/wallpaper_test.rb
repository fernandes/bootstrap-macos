# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/wallpaper'

class WallpaperTest < Minitest::Test
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
    @step = Bootstrap::Steps::Wallpaper.new(shell: @shell)
  end

  def test_name
    assert_equal 'Wallpaper Configuration', @step.name
  end

  def test_installed_returns_false_when_different_wallpaper
    @shell.run_results["osascript -e 'tell application \"System Events\" to get picture of desktop 1'"] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/some/other/wallpaper.png')

    refute @step.installed?
  end

  def test_installed_returns_true_when_blue_violet_set
    @shell.run_results["osascript -e 'tell application \"System Events\" to get picture of desktop 1'"] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/System/Library/Desktop Pictures/Solid Colors/Blue Violet.png')

    assert @step.installed?
  end

  def test_install_sets_wallpaper
    @step.install!
    assert_includes @shell.commands_run,
                    "osascript -e 'tell application \"System Events\" to tell every desktop to set picture to \"/System/Library/Desktop Pictures/Solid Colors/Blue Violet.png\"'"
  end

  def test_run_skips_when_already_configured
    @shell.run_results["osascript -e 'tell application \"System Events\" to get picture of desktop 1'"] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/System/Library/Desktop Pictures/Solid Colors/Blue Violet.png')

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
