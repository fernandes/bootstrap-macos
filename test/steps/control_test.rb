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
  end

  def teardown
    Bootstrap::Config.reset!
    ENV['HOME'] = @original_home
    FileUtils.rm_rf(@tmpdir)
  end

  def test_name
    assert_equal 'Control Repo', @step.name
  end

  def test_installed_returns_false_when_repos_not_present
    refute @step.installed?
  end

  def test_installed_returns_true_when_repos_exist
    config_dir = File.join(@tmpdir, 'config')
    FileUtils.mkdir_p(File.join(config_dir, 'control'))
    FileUtils.mkdir_p(File.join(config_dir, 'caco'))

    assert @step.installed?
  end

  def test_install_clones_caco
    @step.install!

    assert @shell.commands_run.any? { |cmd| cmd.include?('git clone') && cmd.include?('caco') }
  end

  def test_install_clones_control
    @step.install!

    assert @shell.commands_run.any? { |cmd| cmd.include?('git clone') && cmd.include?('control') }
  end

  def test_run_skips_when_repos_exist
    config_dir = File.join(@tmpdir, 'config')
    FileUtils.mkdir_p(File.join(config_dir, 'control'))
    FileUtils.mkdir_p(File.join(config_dir, 'caco'))

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
