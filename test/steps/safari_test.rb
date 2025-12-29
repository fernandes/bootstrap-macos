# frozen_string_literal: true

require_relative '../test_helper'
require 'bootstrap/steps/safari'

class SafariTest < Minitest::Test
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
    @step = Bootstrap::Steps::Safari.new(shell: @shell)
  end

  def test_name
    assert_equal 'Safari Configuration', @step.name
  end

  def test_installed_returns_false_when_full_url_not_shown
    @shell.run_results['defaults read com.apple.Safari ShowFullURLInSmartSearchField'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '0')

    refute @step.installed?
  end

  def test_installed_returns_true_when_configured
    @shell.run_results['defaults read com.apple.Safari ShowFullURLInSmartSearchField'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')

    assert @step.installed?
  end

  def test_install_enables_full_url
    @step.install!
    assert_includes @shell.commands_run, 'defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true'
  end

  def test_run_skips_when_already_configured
    @shell.run_results['defaults read com.apple.Safari ShowFullURLInSmartSearchField'] =
      Struct.new(:success?, :stderr, :output).new(true, '', '1')

    result = @step.run!

    assert_equal :skipped, result[:status]
  end
end
