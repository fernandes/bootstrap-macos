# frozen_string_literal: true

require_relative 'test_helper'

class StepTest < Minitest::Test
  class DummyStep < Bootstrap::Step
    attr_accessor :is_installed, :install_called

    def initialize(**args)
      super
      @is_installed = false
      @install_called = false
    end

    def installed?
      @is_installed
    end

    def install!
      @install_called = true
    end
  end

  def test_name_returns_class_name
    step = DummyStep.new
    assert_equal 'DummyStep', step.name
  end

  def test_run_calls_install_when_not_installed
    step = DummyStep.new
    step.is_installed = false

    result = step.run!

    assert step.install_called
    assert_equal :installed, result[:status]
  end

  def test_run_skips_install_when_already_installed
    step = DummyStep.new
    step.is_installed = true

    result = step.run!

    refute step.install_called
    assert_equal :skipped, result[:status]
  end

  def test_installed_raises_not_implemented_for_base_class
    step = Bootstrap::Step.new
    assert_raises(NotImplementedError) { step.installed? }
  end

  def test_install_raises_not_implemented_for_base_class
    step = Bootstrap::Step.new
    assert_raises(NotImplementedError) { step.install! }
  end
end
