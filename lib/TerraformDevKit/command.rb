require 'open3'

module TerraformDevKit
  class Command
    def self.run(cmd, directory: Dir.pwd, print_output: true, close_stdin: true)
      output = []

      Open3.popen2e(cmd, chdir: directory) do |stdin, stdout_and_stderr, thread|
        stdout_thread = Thread.new do
          process_output(stdout_and_stderr, print_output, output)
        end

        if close_stdin
          stdin.close
        else
          input_thread = Thread.new do
            loop { stdin.puts $stdin.gets }
          end
        end

        thread.join
        stdout_thread.join
        input_thread.terminate unless close_stdin
        raise "Error running command #{cmd}" unless thread.value.success?
      end

      output
    end

    private_class_method
    def self.process_output(stdout_and_stderr, print_output, output)
      line = ''
      stdout_and_stderr.each_char do |char|
        $stdout.print(char) if print_output
        case char
        when "\r"
          next
        when "\n"
          output << line
          line = ''
        else
          line << char
        end
      end

      output << line unless line.empty?
    end
  end
end
