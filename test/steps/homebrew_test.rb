# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/homebrew'
require 'tempfile'

class HomebrewTest < Minitest::Test
  class MockShell
    attr_accessor :existing_files, :run_result, :commands_run

    def initialize
      @existing_files = []
      @run_result = Struct.new(:success?, :stderr).new(true, '')
      @commands_run = []
    end

    def file_exists?(path)
      @existing_files.include?(path)
    end

    def run(command)
      @commands_run << command
      @run_result
    end

    def run_interactive(command)
      @commands_run << command
      @run_result
    end
  end

  def setup
    @shell = MockShell.new
    @step = Bootstrap::Steps::Homebrew.new(shell: @shell)
  end

  def test_name
    assert_equal 'Homebrew', @step.name
  end

  def test_installed_returns_true_when_intel_brew_exists
    @shell.existing_files = ['/usr/local/bin/brew']
    assert @step.installed?
  end

  def test_installed_returns_true_when_arm_brew_exists
    @shell.existing_files = ['/opt/homebrew/bin/brew']
    assert @step.installed?
  end

  def test_installed_returns_false_when_brew_missing
    @shell.existing_files = []
    refute @step.installed?
  end

  def test_run_skips_when_already_installed
    @shell.existing_files = ['/usr/local/bin/brew']
    result = @step.run!
    assert_equal :skipped, result[:status]
  end
end
