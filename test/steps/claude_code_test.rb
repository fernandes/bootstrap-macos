# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/claude_code'

class ClaudeCodeTest < Minitest::Test
  class MockShell
    attr_accessor :run_results, :commands_run

    def initialize
      @run_results = {}
      @commands_run = []
    end

    def run(command)
      @commands_run << command
      @run_results[command] || Struct.new(:success?, :stderr).new(true, '')
    end
  end

  def setup
    @shell = MockShell.new
    @step = Bootstrap::Steps::ClaudeCode.new(shell: @shell)
  end

  def test_name
    assert_equal 'Claude Code', @step.name
  end

  def test_installed_returns_true_when_cask_is_listed
    @shell.run_results['brew list --cask claude-code 2>/dev/null'] =
      Struct.new(:success?, :stderr).new(true, '')
    assert @step.installed?
  end

  def test_installed_returns_false_when_cask_is_not_listed
    @shell.run_results['brew list --cask claude-code 2>/dev/null'] =
      Struct.new(:success?, :stderr).new(false, '')
    refute @step.installed?
  end

  def test_install_runs_brew_install
    @step.install!
    assert_includes @shell.commands_run, 'brew install --cask claude-code'
  end

  def test_install_raises_on_failure
    @shell.run_results['brew install --cask claude-code'] =
      Struct.new(:success?, :stderr).new(false, 'error')
    assert_raises(RuntimeError) { @step.install! }
  end

  def test_run_skips_when_already_installed
    @shell.run_results['brew list --cask claude-code 2>/dev/null'] =
      Struct.new(:success?, :stderr).new(true, '')
    result = @step.run!
    assert_equal :skipped, result[:status]
  end

  def test_run_installs_when_not_installed
    @shell.run_results['brew list --cask claude-code 2>/dev/null'] =
      Struct.new(:success?, :stderr).new(false, '')
    result = @step.run!
    assert_equal :installed, result[:status]
  end
end
