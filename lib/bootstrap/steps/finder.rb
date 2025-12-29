# frozen_string_literal: true

require_relative '../step'

module Bootstrap
  module Steps
    class Finder < Step
      # View styles: Nlsv (List), clmv (Column), icnv (Icon), glyv (Gallery)
      PREFERRED_VIEW_STYLE = 'Nlsv'

      # NewWindowTarget: PfHm (Home), PfDe (Desktop), PfLo (Other)
      NEW_WINDOW_TARGET = 'PfHm'

      # Search scope: SCcf (Current Folder), SCev (This Mac), SCsp (Previous)
      DEFAULT_SEARCH_SCOPE = 'SCcf'

      def name
        'Finder Configuration'
      end

      # Sidebar icon size: 1 (small), 2 (medium), 3 (large)
      SIDEBAR_ICON_SIZE = 1

      def installed?
        view_style_correct? &&
          desktop_icons_hidden? &&
          new_window_target_correct? &&
          show_all_extensions? &&
          remove_old_trash_items? &&
          folders_on_top? &&
          search_scope_correct? &&
          recent_tags_hidden? &&
          show_hidden_files? &&
          path_bar_visible? &&
          save_to_disk_default? &&
          toolbar_rollover_instant? &&
          sidebar_icon_size_correct?
      end

      def install!
        configure_view_style
        configure_desktop_icons
        configure_new_window_target
        configure_show_all_extensions
        configure_trash_settings
        configure_folders_on_top
        configure_search_scope
        configure_sidebar
        configure_hidden_files
        configure_path_bar
        configure_save_location
        configure_toolbar_rollover
        configure_sidebar_icon_size
        restart_finder
      end

      private

      # Checks
      def view_style_correct?
        result = shell.run('defaults read com.apple.finder FXPreferredViewStyle')
        result.success? && result.output.strip == PREFERRED_VIEW_STYLE
      end

      def desktop_icons_hidden?
        %w[ShowHardDrivesOnDesktop ShowExternalHardDrivesOnDesktop
           ShowMountedServersOnDesktop ShowRemovableMediaOnDesktop].all? do |key|
          result = shell.run("defaults read com.apple.finder #{key}")
          result.success? && result.output.strip == '0'
        end
      end

      def new_window_target_correct?
        result = shell.run('defaults read com.apple.finder NewWindowTarget')
        result.success? && result.output.strip == NEW_WINDOW_TARGET
      end

      def show_all_extensions?
        result = shell.run('defaults read NSGlobalDomain AppleShowAllExtensions')
        result.success? && result.output.strip == '1'
      end

      def remove_old_trash_items?
        result = shell.run('defaults read com.apple.finder FXRemoveOldTrashItems')
        result.success? && result.output.strip == '1'
      end

      def folders_on_top?
        result1 = shell.run('defaults read com.apple.finder _FXSortFoldersFirst')
        result2 = shell.run('defaults read com.apple.finder _FXSortFoldersFirstOnDesktop')
        result1.success? && result1.output.strip == '1' &&
          result2.success? && result2.output.strip == '1'
      end

      def search_scope_correct?
        result = shell.run('defaults read com.apple.finder FXDefaultSearchScope')
        result.success? && result.output.strip == DEFAULT_SEARCH_SCOPE
      end

      def recent_tags_hidden?
        result = shell.run('defaults read com.apple.finder ShowRecentTags')
        result.success? && result.output.strip == '0'
      end

      # Configurations
      def configure_view_style
        shell.run("defaults write com.apple.finder FXPreferredViewStyle -string \"#{PREFERRED_VIEW_STYLE}\"")
      end

      def configure_desktop_icons
        shell.run('defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false')
        shell.run('defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false')
        shell.run('defaults write com.apple.finder ShowMountedServersOnDesktop -bool false')
        shell.run('defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false')
      end

      def configure_new_window_target
        shell.run("defaults write com.apple.finder NewWindowTarget -string \"#{NEW_WINDOW_TARGET}\"")
        shell.run("defaults write com.apple.finder NewWindowTargetPath -string \"file://#{ENV['HOME']}/\"")
      end

      def configure_show_all_extensions
        shell.run('defaults write NSGlobalDomain AppleShowAllExtensions -bool true')
      end

      def configure_trash_settings
        shell.run('defaults write com.apple.finder FXRemoveOldTrashItems -bool true')
      end

      def configure_folders_on_top
        shell.run('defaults write com.apple.finder _FXSortFoldersFirst -bool true')
        shell.run('defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true')
      end

      def configure_search_scope
        shell.run("defaults write com.apple.finder FXDefaultSearchScope -string \"#{DEFAULT_SEARCH_SCOPE}\"")
      end

      def configure_sidebar
        shell.run('defaults write com.apple.finder ShowRecentTags -bool false')
        # Note: Recents and Shared sections need to be removed manually via Finder > Settings > Sidebar
      end

      def show_hidden_files?
        result = shell.run('defaults read com.apple.finder AppleShowAllFiles')
        result.success? && result.output.strip == '1'
      end

      def configure_hidden_files
        shell.run('defaults write com.apple.finder AppleShowAllFiles -bool true')
      end

      def path_bar_visible?
        result = shell.run('defaults read com.apple.finder ShowPathbar')
        result.success? && result.output.strip == '1'
      end

      def configure_path_bar
        shell.run('defaults write com.apple.finder ShowPathbar -bool true')
      end

      def save_to_disk_default?
        result = shell.run('defaults read NSGlobalDomain NSDocumentSaveNewDocumentsToCloud')
        result.success? && result.output.strip == '0'
      end

      def configure_save_location
        shell.run('defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false')
      end

      def toolbar_rollover_instant?
        result = shell.run('defaults read NSGlobalDomain NSToolbarTitleViewRolloverDelay')
        result.success? && result.output.strip.to_f == 0
      end

      def configure_toolbar_rollover
        shell.run('defaults write NSGlobalDomain NSToolbarTitleViewRolloverDelay -float 0')
      end

      def sidebar_icon_size_correct?
        result = shell.run('defaults read NSGlobalDomain NSTableViewDefaultSizeMode')
        result.success? && result.output.strip.to_i == SIDEBAR_ICON_SIZE
      end

      def configure_sidebar_icon_size
        shell.run("defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int #{SIDEBAR_ICON_SIZE}")
      end

      def restart_finder
        shell.run('killall Finder')
      end
    end
  end
end
