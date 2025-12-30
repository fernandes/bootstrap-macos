# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/hostname'
require 'bootstrap/config'

class HostnameTest < Minitest::Test
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

  MOCK_CONFIG = {
    'mac' => {
      'hostname' => 'adamantium'
    }
  }.freeze

  def setup
    @shell = MockShell.new
    @step = Bootstrap::Steps::Hostname.new(shell: @shell)
    Bootstrap::Config.load_from_hash(MOCK_CONFIG)
  end

  def teardown
    Bootstrap::Config.reset!
  end

  def test_name
    assert_equal 'Hostname', @step.name
  end

  def test_installed_returns_true_when_hostname_matches
    @shell.run_results['scutil --get ComputerName'] =
      Struct.new(:success?, :stderr, :output).new(true, '', "adamantium\n")

    assert @step.installed?
  end

  def test_installed_returns_false_when_hostname_differs
    @shell.run_results['scutil --get ComputerName'] =
      Struct.new(:success?, :stderr, :output).new(true, '', "other-hostname\n")

    refute @step.installed?
  end

  def test_install_sets_all_hostname_types
    @step.install!

    assert_includes @shell.commands_run, 'sudo scutil --set ComputerName adamantium'
    assert_includes @shell.commands_run, 'sudo scutil --set HostName adamantium'
    assert_includes @shell.commands_run, 'sudo scutil --set LocalHostName adamantium'
  end

  def test_run_skips_when_hostname_matches
    @shell.run_results['scutil --get ComputerName'] =
      Struct.new(:success?, :stderr, :output).new(true, '', "adamantium\n")

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
