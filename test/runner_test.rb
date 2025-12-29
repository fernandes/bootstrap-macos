# frozen_string_literal: true

require_relative 'test_helper'
require 'bootstrap/runner'
require 'stringio'

class RunnerTest < Minitest::Test
  class MockStep
    attr_reader :name, :run_result

    def initialize(name:, status:)
      @name = name
      @run_result = { status: status, message: "#{name} #{status}" }
    end

    def run!
      @run_result
    end
  end

  def test_run_executes_all_steps
    steps = [
      MockStep.new(name: 'Step1', status: :installed),
      MockStep.new(name: 'Step2', status: :skipped)
    ]
    output = StringIO.new
    runner = Bootstrap::Runner.new(steps: steps, output: output)

    results = runner.run!

    assert_equal 2, results.size
    assert_equal :installed, results[0][:status]
    assert_equal :skipped, results[1][:status]
  end

  def test_run_prints_header
    steps = []
    output = StringIO.new
    runner = Bootstrap::Runner.new(steps: steps, output: output)

    runner.run!

    assert_includes output.string, 'macOS Bootstrap'
  end

  def test_run_prints_summary
    steps = [
      MockStep.new(name: 'Step1', status: :installed),
      MockStep.new(name: 'Step2', status: :skipped)
    ]
    output = StringIO.new
    runner = Bootstrap::Runner.new(steps: steps, output: output)

    runner.run!

    assert_includes output.string, 'Installed: 1'
    assert_includes output.string, 'Skipped:   1'
  end

  def test_run_prints_step_status
    steps = [MockStep.new(name: 'TestStep', status: :installed)]
    output = StringIO.new
    runner = Bootstrap::Runner.new(steps: steps, output: output)

    runner.run!

    assert_includes output.string, 'TestStep'
    assert_includes output.string, 'installed'
  end
end
