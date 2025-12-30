# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/control'
require 'bootstrap/config'
require 'fileutils'
require 'tmpdir'

class ControlTest < Minitest::Test
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

    def run_interactive(command)
      @commands_run << command
      @run_results[command] || Struct.new(:success?, :stderr, :output).new(true, '', '')
    end

    def run_interactive_with_output(command)
      @commands_run << command
      @run_results[command] || Struct.new(:success?, :stderr, :output).new(true, '', 'session123')
    end
  end

  MOCK_CONFIG = {
    'control' => {
      'repo' => 'git@github.com:user/control.git',
      'caco_repo' => 'https://github.com/fernandes/caco'
    }
  }.freeze

  def setup
    @shell = MockShell.new
    @step = Bootstrap::Steps::Control.new(shell: @shell)
    @tmpdir = Dir.mktmpdir
    Bootstrap::Config.load_from_hash(MOCK_CONFIG)

    @original_home = ENV['HOME']
    ENV['HOME'] = @tmpdir

    # Default mock for Bitwarden commands
    setup_bitwarden_mocks
  end

  def teardown
    Bootstrap::Config.reset!
    ENV['HOME'] = @original_home
    FileUtils.rm_rf(@tmpdir)
  end

  def setup_bitwarden_mocks
    @shell.run_results['bw status'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '{"status":"unlocked"}')
    @shell.run_results["bw get item 'Control Repo' --session 'session123'"] =
      Struct.new(:success?, :stderr, :output).new(true, '', '{"id":"item-123"}')
  end

  def setup_keys_present
    config_dir = File.join(@tmpdir, 'config')
    @keys_path = File.join(config_dir, 'control', 'keys')
    FileUtils.mkdir_p(@keys_path)
    FileUtils.touch(File.join(@keys_path, 'private_key.pkcs7.pem'))
    FileUtils.touch(File.join(@keys_path, 'public_key.pkcs7.pem'))
  end

  def setup_keys_only(control_path)
    keys_path = File.join(control_path, 'keys')
    FileUtils.mkdir_p(keys_path)
    FileUtils.touch(File.join(keys_path, 'private_key.pkcs7.pem'))
    FileUtils.touch(File.join(keys_path, 'public_key.pkcs7.pem'))
  end

  def setup_all_installed
    config_dir = File.join(@tmpdir, 'config')
    control_path = File.join(config_dir, 'control')
    keys_path = File.join(control_path, 'keys')
    FileUtils.mkdir_p(keys_path)
    FileUtils.mkdir_p(File.join(config_dir, 'caco'))
    FileUtils.touch(File.join(keys_path, 'private_key.pkcs7.pem'))
    FileUtils.touch(File.join(keys_path, 'public_key.pkcs7.pem'))

    @shell.run_results['brew list --formula'] =
      Struct.new(:success?, :stderr, :output).new(true, '', "augeas\npkgconf")
    @shell.run_results["cd #{control_path} && mise current"] =
      Struct.new(:success?, :stderr, :output).new(true, '', 'ruby 3.3.0')
    @shell.run_results["cd #{control_path} && eval \"$(mise activate bash)\" && bundle check"] =
      Struct.new(:success?, :stderr, :output).new(true, '', 'The Gemfile dependencies are satisfied')
  end

  def test_name
    assert_equal 'Control Repo', @step.name
  end

  def test_installed_returns_false_when_repos_not_present
    refute @step.installed?
  end

  def test_installed_returns_true_when_all_configured
    setup_all_installed

    # Override log_file_exists? to return true for this test
    @step.define_singleton_method(:log_file_exists?) { true }

    assert @step.installed?
  end

  def test_installed_returns_false_when_deps_missing
    config_dir = File.join(@tmpdir, 'config')
    FileUtils.mkdir_p(File.join(config_dir, 'control'))
    FileUtils.mkdir_p(File.join(config_dir, 'caco'))
    @shell.run_results['brew list --formula'] =
      Struct.new(:success?, :stderr, :output).new(true, '', "augeas\nother-package")

    refute @step.installed?
  end

  def test_install_clones_caco
    # Don't setup_keys_present here - we want to test git clone
    @step.install!

    assert @shell.commands_run.any? { |cmd| cmd.include?('git clone') && cmd.include?('caco') }
  end

  def test_install_clones_control
    # Don't setup_keys_present here - we want to test git clone
    @step.install!

    assert @shell.commands_run.any? { |cmd| cmd.include?('git clone') && cmd.include?('control') }
  end

  def test_install_installs_missing_brew_deps
    setup_keys_present
    @shell.run_results['brew list --formula'] =
      Struct.new(:success?, :stderr, :output).new(true, '', "openssl@3\nreadline")

    @step.install!

    assert_includes @shell.commands_run, 'brew install augeas pkgconf'
  end

  def test_install_skips_brew_deps_when_all_installed
    setup_keys_present
    @shell.run_results['brew list --formula'] =
      Struct.new(:success?, :stderr, :output).new(true, '', "openssl@3\nreadline\naugeas\npkgconf")

    @step.install!

    refute @shell.commands_run.any? { |cmd| cmd.start_with?('brew install') }
  end

  def test_install_runs_mise_install
    setup_keys_present
    config_dir = File.join(@tmpdir, 'config')
    control_path = File.join(config_dir, 'control')
    FileUtils.mkdir_p(control_path)

    @shell.run_results["cd #{control_path} && mise current"] =
      Struct.new(:success?, :stderr, :output).new(true, '', 'ruby 3.3.0 (not installed)')

    @step.install!

    assert @shell.commands_run.any? { |cmd| cmd.include?('mise install') }
  end

  def test_install_skips_mise_when_tools_installed
    setup_keys_present
    config_dir = File.join(@tmpdir, 'config')
    control_path = File.join(config_dir, 'control')
    FileUtils.mkdir_p(control_path)

    @shell.run_results["cd #{control_path} && mise current"] =
      Struct.new(:success?, :stderr, :output).new(true, '', 'ruby 3.3.0')

    @step.install!

    refute @shell.commands_run.any? { |cmd| cmd.include?('mise install') }
  end

  def test_install_runs_bundle_install
    setup_keys_present
    config_dir = File.join(@tmpdir, 'config')
    control_path = File.join(config_dir, 'control')
    FileUtils.mkdir_p(control_path)

    @shell.run_results["cd #{control_path} && eval \"$(mise activate bash)\" && bundle check"] =
      Struct.new(:success?, :stderr, :output).new(false, '', '')

    @step.install!

    assert @shell.commands_run.any? { |cmd| cmd.include?('bundle install') }
  end

  def test_install_skips_bundle_when_deps_satisfied
    setup_keys_present
    config_dir = File.join(@tmpdir, 'config')
    control_path = File.join(config_dir, 'control')
    FileUtils.mkdir_p(control_path)

    @shell.run_results["cd #{control_path} && eval \"$(mise activate bash)\" && bundle check"] =
      Struct.new(:success?, :stderr, :output).new(true, '', 'The Gemfile dependencies are satisfied')

    @step.install!

    refute @shell.commands_run.any? { |cmd| cmd.include?('bundle install') }
  end

  def test_install_creates_log_file
    setup_keys_present

    # Override log_file_exists? to return false for this test
    @step.define_singleton_method(:log_file_exists?) { false }

    @step.install!

    assert @shell.commands_run.any? { |cmd| cmd.include?('sudo touch /var/log/caco.log') }
    assert @shell.commands_run.any? { |cmd| cmd.include?('sudo chown') && cmd.include?('/var/log/caco.log') }
  end

  def test_install_fetches_keys_from_bitwarden
    @step.install!

    assert @shell.commands_run.any? { |cmd| cmd.include?('bw get attachment') && cmd.include?('private_key.pkcs7.pem') }
    assert @shell.commands_run.any? { |cmd| cmd.include?('bw get attachment') && cmd.include?('public_key.pkcs7.pem') }
  end

  def test_install_skips_keys_when_already_present
    setup_keys_present

    @step.install!

    refute @shell.commands_run.any? { |cmd| cmd.include?('bw get attachment') }
  end
end
