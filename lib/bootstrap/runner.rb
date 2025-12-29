# frozen_string_literal: true

module Bootstrap
  class Runner
    COLORS = {
      green: "\e[32m",
      yellow: "\e[33m",
      red: "\e[31m",
      blue: "\e[34m",
      reset: "\e[0m"
    }.freeze

    attr_reader :steps, :output

    def initialize(steps:, output: $stdout)
      @steps = steps
      @output = output
    end

    def run!
      results = []

      print_header

      steps.each do |step|
        print_step_start(step)
        result = step.run!
        results << { step: step.name, **result }
        print_step_result(step, result)
      end

      print_summary(results)
      results
    end

    private

    def print_header
      output.puts
      output.puts "#{COLORS[:blue]}=== macOS Bootstrap ==#{COLORS[:reset]}"
      output.puts
    end

    def print_step_start(step)
      output.print "#{COLORS[:blue]}[...]#{COLORS[:reset]} #{step.name}... "
    end

    def print_step_result(step, result)
      case result[:status]
      when :installed
        output.puts "#{COLORS[:green]}installed#{COLORS[:reset]}"
      when :skipped
        output.puts "#{COLORS[:yellow]}skipped#{COLORS[:reset]}"
      else
        output.puts "#{COLORS[:red]}failed#{COLORS[:reset]}"
      end
    end

    def print_summary(results)
      installed = results.count { |r| r[:status] == :installed }
      skipped = results.count { |r| r[:status] == :skipped }

      output.puts
      output.puts "#{COLORS[:blue]}=== Summary ==#{COLORS[:reset]}"
      output.puts "  Installed: #{installed}"
      output.puts "  Skipped:   #{skipped}"
      output.puts
    end
  end
end
