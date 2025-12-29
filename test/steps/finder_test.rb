# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/finder'

class FinderTest < Minitest::Test
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
    @step = Bootstrap::Steps::Finder.new(shell: @shell)
  end

  def setup_all_configured
    @shell.run_results['defaults read com.apple.finder FXPreferredViewStyle'] =
      Struct.new(:success?, :stderr, :output).new(true, '', 'Nlsv')
    @shell.run_results['defaults read com.apple.finder ShowHardDrivesOnDesktop'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '0')
    @shell.run_results['defaults read com.apple.finder ShowExternalHardDrivesOnDesktop'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '0')
    @shell.run_results['defaults read com.apple.finder ShowMountedServersOnDesktop'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '0')
    @shell.run_results['defaults read com.apple.finder ShowRemovableMediaOnDesktop'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '0')
    @shell.run_results['defaults read com.apple.finder NewWindowTarget'] =
      Struct.new(:success?, :stderr, :output).new(true, '', 'PfHm')
    @shell.run_results['defaults read NSGlobalDomain AppleShowAllExtensions'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read com.apple.finder FXRemoveOldTrashItems'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read com.apple.finder _FXSortFoldersFirst'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read com.apple.finder _FXSortFoldersFirstOnDesktop'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read com.apple.finder FXDefaultSearchScope'] =
      Struct.new(:success?, :stderr, :output).new(true, '', 'SCcf')
    @shell.run_results['defaults read com.apple.finder ShowRecentTags'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '0')
    @shell.run_results['defaults read com.apple.finder AppleShowAllFiles'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read com.apple.finder ShowPathbar'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read NSGlobalDomain NSDocumentSaveNewDocumentsToCloud'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '0')
    @shell.run_results['defaults read NSGlobalDomain NSToolbarTitleViewRolloverDelay'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '0')
    @shell.run_results['defaults read NSGlobalDomain NSTableViewDefaultSizeMode'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read NSGlobalDomain NSNavPanelExpandedStateForSaveMode'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read NSGlobalDomain NSNavPanelExpandedStateForSaveMode2'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read NSGlobalDomain PMPrintingExpandedStateForPrint'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
    @shell.run_results['defaults read NSGlobalDomain PMPrintingExpandedStateForPrint2'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')
  end

  def test_name
    assert_equal 'Finder Configuration', @step.name
  end

  def test_installed_returns_false_when_view_style_not_set
    @shell.run_results['defaults read com.apple.finder FXPreferredViewStyle'] =
      Struct.new(:success?, :stderr, :output).new(true, '', 'icnv')

    refute @step.installed?
  end

  def test_installed_returns_true_when_all_configured
    setup_all_configured
    assert @step.installed?
  end

  def test_installed_returns_false_when_desktop_icons_shown
    setup_all_configured
    @shell.run_results['defaults read com.apple.finder ShowHardDrivesOnDesktop'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')

    refute @step.installed?
  end

  def test_install_sets_view_style
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"'
  end

  def test_install_hides_desktop_icons
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false'
    assert_includes @shell.commands_run, 'defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false'
    assert_includes @shell.commands_run, 'defaults write com.apple.finder ShowMountedServersOnDesktop -bool false'
    assert_includes @shell.commands_run, 'defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false'
  end

  def test_install_sets_new_window_target
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.finder NewWindowTarget -string "PfHm"'
  end

  def test_install_shows_all_extensions
    @step.install!
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain AppleShowAllExtensions -bool true'
  end

  def test_install_configures_trash
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.finder FXRemoveOldTrashItems -bool true'
  end

  def test_install_sets_folders_on_top
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.finder _FXSortFoldersFirst -bool true'
    assert_includes @shell.commands_run, 'defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true'
  end

  def test_install_sets_search_scope
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"'
  end

  def test_install_hides_recent_tags
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.finder ShowRecentTags -bool false'
  end

  def test_install_shows_hidden_files
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.finder AppleShowAllFiles -bool true'
  end

  def test_install_shows_path_bar
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.finder ShowPathbar -bool true'
  end

  def test_install_sets_save_to_disk
    @step.install!
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false'
  end

  def test_install_sets_toolbar_rollover
    @step.install!
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain NSToolbarTitleViewRolloverDelay -float 0'
  end

  def test_install_sets_sidebar_icon_size
    @step.install!
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1'
  end

  def test_install_expands_dialogs
    @step.install!
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true'
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true'
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true'
    assert_includes @shell.commands_run, 'defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true'
  end

  def test_install_restarts_finder
    @step.install!
    assert_includes @shell.commands_run, 'killall Finder'
  end

  def test_run_skips_when_already_configured
    setup_all_configured

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
