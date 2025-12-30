# frozen_string_literal: true

require 'open3'

module Bootstrap
  class Shell
    Result = Struct.new(:stdout, :stderr, :status, keyword_init: true) do
      def success?
        status.success?
      end

      def output
        stdout.to_s.strip
      end
    end

    def self.run(command)
      stdout, stderr, status = Open3.capture3(command)
      Result.new(stdout: stdout, stderr: stderr, status: status)
    end

    def self.run_interactive(command)
      system(command)
      Result.new(stdout: '', stderr: '', status: $?)
    end

    def self.run_interactive_with_output(command)
      # Uses backticks but bw prompts via /dev/tty so it's still interactive
      output = `#{command}`
      Result.new(stdout: output, stderr: '', status: $?)
    end

    def self.success?(command)
      run(command).success?
    end

    def self.which(program)
      result = run("which #{program}")
      result.success? ? result.output : nil
    end

    def self.file_exists?(path)
      File.exist?(path)
    end

    def self.directory_exists?(path)
      File.directory?(path)
    end
  end
end
