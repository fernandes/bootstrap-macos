# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/display'

class DisplayTest < Minitest::Test
  class MockShell
    attr_accessor :commands_run, :run_results, :success_results

    def initialize
      @commands_run = []
      @run_results = {}
      @success_results = {}
    end

    def run(command)
      @commands_run << command
      @run_results[command] || default_result
    end

    def success?(command)
      @commands_run << command
      @success_results.fetch(command, false)
    end

    private

    def default_result
      Struct.new(:success?, :stderr, :output).new(true, '', '')
    end
  end

  def setup
    @shell = MockShell.new
    @step = Bootstrap::Steps::Display.new(shell: @shell)
  end

  def test_name
    assert_equal 'Display Resolution', @step.name
  end

  def test_installed_returns_false_when_displayplacer_not_installed
    @shell.success_results['which displayplacer'] = false
    refute @step.installed?
  end

  def test_installed_returns_false_when_resolution_does_not_match
    @shell.success_results['which displayplacer'] = true
    @shell.run_results['displayplacer list'] = Struct.new(:success?, :stderr, :output).new(
      true, '', "Resolution: 1920x1080\nmode 198: res:2304x1440 hz:59 color_depth:8"
    )
    refute @step.installed?
  end

  def test_installed_returns_true_when_displayplacer_installed_and_resolution_matches
    @shell.success_results['which displayplacer'] = true
    @shell.run_results['displayplacer list'] = Struct.new(:success?, :stderr, :output).new(
      true, '', 'Resolution: 2304x1440'
    )
    assert @step.installed?
  end

  def test_install_installs_displayplacer_when_not_present
    @shell.success_results['which displayplacer'] = false
    @shell.run_results['brew install displayplacer'] = Struct.new(:success?, :stderr, :output).new(
      true, '', ''
    )
    @shell.run_results['displayplacer list'] = Struct.new(:success?, :stderr, :output).new(
      true, '', "Persistent screen id: ABC123\nResolution: 1920x1080\nmode 199: res:2304x1440 hz:59 color_depth:8"
    )

    @step.install!

    assert_includes @shell.commands_run, 'brew install displayplacer'
  end

  def test_install_configures_resolution_using_mode
    @shell.success_results['which displayplacer'] = true
    @shell.run_results['displayplacer list'] = Struct.new(:success?, :stderr, :output).new(
      true, '', "Persistent screen id: ABC123\nResolution: 1920x1080\nmode 199: res:2304x1440 hz:59 color_depth:8"
    )

    @step.install!

    assert @shell.commands_run.any? { |cmd| cmd.include?('displayplacer "id:ABC123 mode:199"') }
  end

  def test_install_skips_resolution_when_already_configured
    @shell.success_results['which displayplacer'] = true
    @shell.run_results['displayplacer list'] = Struct.new(:success?, :stderr, :output).new(
      true, '', "Persistent screen id: ABC123\nResolution: 2304x1440"
    )

    @step.install!

    refute @shell.commands_run.any? { |cmd| cmd.include?('displayplacer "id:') }
  end

  def test_run_skips_when_already_configured
    @shell.success_results['which displayplacer'] = true
    @shell.run_results['displayplacer list'] = Struct.new(:success?, :stderr, :output).new(
      true, '', 'Resolution: 2304x1440'
    )

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
