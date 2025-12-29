# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/xcode'

class XcodeTest < Minitest::Test
  class MockShell
    attr_accessor :directory_exists_result, :run_result, :commands_run
    attr_accessor :install_simulates_success

    def initialize
      @directory_exists_result = false
      @run_result = Struct.new(:success?, :stderr).new(true, '')
      @commands_run = []
      @install_simulates_success = false
    end

    def directory_exists?(_path)
      # If install was triggered and should succeed, return true after first check
      if @install_simulates_success && @commands_run.include?('xcode-select --install')
        true
      else
        @directory_exists_result
      end
    end

    def run(command)
      @commands_run << command
      @run_result
    end
  end

  def setup
    @shell = MockShell.new
    @step = Bootstrap::Steps::Xcode.new(shell: @shell)
    @step.instance_variable_set(:@poll_interval, 0.001)
    @step.instance_variable_set(:@max_wait_time, 0.005)
  end

  def test_name
    assert_equal 'Xcode Command Line Tools', @step.name
  end

  def test_installed_returns_true_when_tools_directory_exists
    @shell.directory_exists_result = true
    assert @step.installed?
  end

  def test_installed_returns_false_when_tools_directory_missing
    @shell.directory_exists_result = false
    refute @step.installed?
  end

  def test_install_runs_xcode_select
    @shell.install_simulates_success = true
    @step.install!
    assert_includes @shell.commands_run, 'xcode-select --install'
  end

  def test_install_waits_for_installation
    @shell.install_simulates_success = true
    @step.install!
    assert_includes @shell.commands_run, 'xcode-select --install'
  end

  def test_install_raises_on_timeout
    @shell.directory_exists_result = false
    @shell.install_simulates_success = false
    assert_raises(RuntimeError) { @step.install! }
  end

  def test_run_skips_when_already_installed
    @shell.directory_exists_result = true
    result = @step.run!
    assert_equal :skipped, result[:status]
    assert_empty @shell.commands_run
  end

  def test_run_installs_when_not_installed
    @shell.install_simulates_success = true
    result = @step.run!
    assert_equal :installed, result[:status]
    refute_empty @shell.commands_run
  end
end
