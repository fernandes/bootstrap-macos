# frozen_string_literal: true

require_relative 'test_helper'

class ShellTest < Minitest::Test
  def test_run_returns_result_with_stdout
    result = Bootstrap::Shell.run('echo hello')
    assert result.success?
    assert_equal 'hello', result.output
  end

  def test_run_captures_stderr
    result = Bootstrap::Shell.run('echo error >&2')
    assert result.success?
    assert_includes result.stderr, 'error'
  end

  def test_run_returns_failure_for_bad_command
    result = Bootstrap::Shell.run('exit 1')
    refute result.success?
  end

  def test_run_interactive_returns_success_for_good_command
    result = Bootstrap::Shell.run_interactive('true')
    assert result.success?
  end

  def test_run_interactive_returns_failure_for_bad_command
    result = Bootstrap::Shell.run_interactive('false')
    refute result.success?
  end

  def test_success_returns_true_for_successful_command
    assert Bootstrap::Shell.success?('true')
  end

  def test_success_returns_false_for_failed_command
    refute Bootstrap::Shell.success?('false')
  end

  def test_which_returns_path_for_existing_command
    path = Bootstrap::Shell.which('ruby')
    assert path
    assert path.include?('ruby')
  end

  def test_which_returns_nil_for_missing_command
    path = Bootstrap::Shell.which('nonexistent_command_xyz')
    assert_nil path
  end

  def test_file_exists_returns_true_for_existing_file
    assert Bootstrap::Shell.file_exists?(__FILE__)
  end

  def test_file_exists_returns_false_for_missing_file
    refute Bootstrap::Shell.file_exists?('/nonexistent/file')
  end

  def test_directory_exists_returns_true_for_existing_directory
    assert Bootstrap::Shell.directory_exists?(File.dirname(__FILE__))
  end

  def test_directory_exists_returns_false_for_missing_directory
    refute Bootstrap::Shell.directory_exists?('/nonexistent/directory')
  end
end
