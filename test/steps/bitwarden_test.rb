# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/bitwarden'
require 'bootstrap/config'

class BitwardenTest < Minitest::Test
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
    'bitwarden' => {
      'server' => 'https://vault.example.com'
    }
  }.freeze

  def setup
    @shell = MockShell.new
    @step = Bootstrap::Steps::Bitwarden.new(shell: @shell)
    Bootstrap::Config.load_from_hash(MOCK_CONFIG)
  end

  def teardown
    Bootstrap::Config.reset!
  end

  def test_name
    assert_equal 'Bitwarden CLI', @step.name
  end

  def test_installed_returns_false_when_cli_not_installed
    @shell.run_results['which bw'] =
      Struct.new(:success?, :stderr, :output).new(false, '', '')

    refute @step.installed?
  end

  def test_installed_returns_false_when_server_not_configured
    @shell.run_results['which bw'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/opt/homebrew/bin/bw')
    @shell.run_results['bw config server'] =
      Struct.new(:success?, :stderr, :output).new(true, '', 'https://other.server.com')

    refute @step.installed?
  end

  def test_installed_returns_true_when_configured
    @shell.run_results['which bw'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/opt/homebrew/bin/bw')
    @shell.run_results['bw config server'] =
      Struct.new(:success?, :stderr, :output).new(true, '', 'https://vault.example.com')

    assert @step.installed?
  end

  def test_install_installs_cli_when_missing
    @shell.run_results['which bw'] =
      Struct.new(:success?, :stderr, :output).new(false, '', '')

    @step.install!

    assert_includes @shell.commands_run, 'brew install bitwarden-cli'
  end

  def test_install_configures_server
    @shell.run_results['which bw'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/opt/homebrew/bin/bw')

    @step.install!

    assert_includes @shell.commands_run, 'bw config server https://vault.example.com'
  end

  def test_run_skips_when_already_configured
    @shell.run_results['which bw'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/opt/homebrew/bin/bw')
    @shell.run_results['bw config server'] =
      Struct.new(:success?, :stderr, :output).new(true, '', 'https://vault.example.com')

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
