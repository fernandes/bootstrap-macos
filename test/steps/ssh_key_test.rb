# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/ssh_key'
require 'bootstrap/config'
require 'fileutils'
require 'tmpdir'

class SshKeyTest < Minitest::Test
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
      Struct.new(:success?, :stderr, :output).new(true, '', '')
    end

    def run_interactive_with_output(command)
      @commands_run << command
      @run_results[command] || Struct.new(:success?, :stderr, :output).new(true, '', 'mock_session_token')
    end
  end

  MOCK_CONFIG = {
    'bitwarden' => {
      'server' => 'https://vault.example.com',
      'ssh_item' => 'SSH Key'
    },
    'ssh' => {
      'key_name' => 'id_ed25519'
    }
  }.freeze

  def setup
    @shell = MockShell.new
    @step = Bootstrap::Steps::SshKey.new(shell: @shell)
    @tmpdir = Dir.mktmpdir
    Bootstrap::Config.load_from_hash(MOCK_CONFIG)

    # Mock home directory
    @original_home = ENV['HOME']
    ENV['HOME'] = @tmpdir
  end

  def teardown
    Bootstrap::Config.reset!
    ENV['HOME'] = @original_home
    FileUtils.rm_rf(@tmpdir)
  end

  def test_name
    assert_equal 'SSH Key', @step.name
  end

  def test_installed_returns_false_when_key_not_present
    refute @step.installed?
  end

  def test_installed_returns_true_when_key_exists
    ssh_dir = File.join(@tmpdir, '.ssh')
    FileUtils.mkdir_p(ssh_dir)
    File.write(File.join(ssh_dir, 'id_ed25519'), 'test_key')

    assert @step.installed?
  end

  def test_run_skips_when_key_exists
    ssh_dir = File.join(@tmpdir, '.ssh')
    FileUtils.mkdir_p(ssh_dir)
    File.write(File.join(ssh_dir, 'id_ed25519'), 'test_key')

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
