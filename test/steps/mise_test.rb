# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/mise'
require 'fileutils'
require 'tmpdir'

class MiseTest < Minitest::Test
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
    @step = Bootstrap::Steps::Mise.new(shell: @shell)
    @tmpdir = Dir.mktmpdir
    @original_home = ENV['HOME']
    ENV['HOME'] = @tmpdir
  end

  def teardown
    ENV['HOME'] = @original_home
    FileUtils.rm_rf(@tmpdir)
  end

  def setup_all_configured
    @shell.run_results['which mise'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/opt/homebrew/bin/mise')
    @shell.run_results['mise settings get idiomatic_version_file_enable_tools'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '["ruby"]')
    File.write(File.join(@tmpdir, '.zshrc'), 'eval "$(mise activate zsh)"')
  end

  def test_name
    assert_equal 'Mise', @step.name
  end

  def test_installed_returns_false_when_cli_not_installed
    @shell.run_results['which mise'] =
      Struct.new(:success?, :stderr, :output).new(false, '', '')

    refute @step.installed?
  end

  def test_installed_returns_false_when_ruby_version_file_not_enabled
    @shell.run_results['which mise'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/opt/homebrew/bin/mise')
    @shell.run_results['mise settings get idiomatic_version_file_enable_tools'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '[]')

    refute @step.installed?
  end

  def test_installed_returns_true_when_configured
    setup_all_configured

    assert @step.installed?
  end

  def test_install_installs_missing_ruby_build_deps
    @shell.run_results['brew list --formula'] =
      Struct.new(:success?, :stderr, :output).new(true, '', "openssl@3\nreadline")

    @step.install!

    assert_includes @shell.commands_run, 'brew install libyaml gmp autoconf'
  end

  def test_install_skips_ruby_build_deps_when_all_installed
    @shell.run_results['brew list --formula'] =
      Struct.new(:success?, :stderr, :output).new(true, '', "openssl@3\nreadline\nlibyaml\ngmp\nautoconf")

    @step.install!

    refute @shell.commands_run.any? { |cmd| cmd.start_with?('brew install') && cmd.include?('openssl') }
  end

  def test_install_runs_brew_install_when_cli_missing
    @shell.run_results['which mise'] =
      Struct.new(:success?, :stderr, :output).new(false, '', '')

    @step.install!

    assert_includes @shell.commands_run, 'brew install mise'
  end

  def test_install_configures_ruby_version_file
    @shell.run_results['which mise'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/opt/homebrew/bin/mise')

    @step.install!

    assert_includes @shell.commands_run, 'mise settings add idiomatic_version_file_enable_tools ruby'
  end

  def test_install_activates_in_zsh
    @shell.run_results['which mise'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/opt/homebrew/bin/mise')

    @step.install!

    zshrc_content = File.read(File.join(@tmpdir, '.zshrc'))
    assert_includes zshrc_content, 'eval "$(mise activate zsh)"'
  end

  def test_installed_returns_false_when_zsh_not_activated
    @shell.run_results['which mise'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '/opt/homebrew/bin/mise')
    @shell.run_results['mise settings get idiomatic_version_file_enable_tools'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '["ruby"]')
    File.write(File.join(@tmpdir, '.zshrc'), '# empty')

    refute @step.installed?
  end

  def test_run_skips_when_already_configured
    setup_all_configured

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
