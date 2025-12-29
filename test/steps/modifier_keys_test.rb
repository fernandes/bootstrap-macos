# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/modifier_keys'
require 'tempfile'
require 'fileutils'

class ModifierKeysTest < Minitest::Test
  class MockShell
    attr_accessor :commands_run, :run_results, :existing_files

    def initialize
      @commands_run = []
      @run_results = {}
      @existing_files = []
    end

    def run(command)
      @commands_run << command
      @run_results[command] || Struct.new(:success?, :stderr, :output).new(true, '', '')
    end

    def file_exists?(path)
      @existing_files.include?(path)
    end
  end

  def setup
    @shell = MockShell.new
    @step = Bootstrap::Steps::ModifierKeys.new(shell: @shell)
    @temp_dir = Dir.mktmpdir
    @original_plist_path = Bootstrap::Steps::ModifierKeys::PLIST_PATH
  end

  def teardown
    FileUtils.rm_rf(@temp_dir)
  end

  def test_name
    assert_equal 'Modifier Keys (Caps Lock <-> Control)', @step.name
  end

  def test_installed_returns_false_when_plist_does_not_exist
    @shell.existing_files = []
    refute @step.installed?
  end

  def test_installed_returns_true_when_plist_exists
    @shell.existing_files = [Bootstrap::Steps::ModifierKeys::PLIST_PATH]
    assert @step.installed?
  end

  def test_install_applies_key_mapping_with_hidutil
    # Use a temp directory for the plist
    temp_plist = File.join(@temp_dir, 'com.bootstrap.KeyRemapping.plist')
    Bootstrap::Steps::ModifierKeys.send(:remove_const, :PLIST_PATH)
    Bootstrap::Steps::ModifierKeys.const_set(:PLIST_PATH, temp_plist)

    @step.install!

    hidutil_command = @shell.commands_run.find { |cmd| cmd.include?('hidutil') }
    assert hidutil_command, 'Expected hidutil command to be run'
    assert_includes hidutil_command, 'UserKeyMapping'
    assert_includes hidutil_command, '0x700000039'
    assert_includes hidutil_command, '0x7000000E0'

    # Restore original constant
    Bootstrap::Steps::ModifierKeys.send(:remove_const, :PLIST_PATH)
    Bootstrap::Steps::ModifierKeys.const_set(:PLIST_PATH, @original_plist_path)
  end

  def test_install_creates_launch_agent_plist
    temp_plist = File.join(@temp_dir, 'LaunchAgents', 'com.bootstrap.KeyRemapping.plist')
    Bootstrap::Steps::ModifierKeys.send(:remove_const, :PLIST_PATH)
    Bootstrap::Steps::ModifierKeys.const_set(:PLIST_PATH, temp_plist)

    @step.install!

    assert File.exist?(temp_plist), 'Expected plist file to be created'
    content = File.read(temp_plist)
    assert_includes content, 'com.bootstrap.KeyRemapping'
    assert_includes content, 'hidutil'

    # Restore original constant
    Bootstrap::Steps::ModifierKeys.send(:remove_const, :PLIST_PATH)
    Bootstrap::Steps::ModifierKeys.const_set(:PLIST_PATH, @original_plist_path)
  end

  def test_run_skips_when_already_configured
    @shell.existing_files = [Bootstrap::Steps::ModifierKeys::PLIST_PATH]

    result = @step.run!

    assert_equal :skipped, result[:status]
    assert_empty @shell.commands_run
  end
end
