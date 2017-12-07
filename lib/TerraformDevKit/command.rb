require 'open3'

module TerraformDevKit
  class Command
    def self.run(cmd, directory: Dir.pwd, print_output: true)
      Open3.popen3(cmd, chdir: directory) do |_, stdout, stderr, thread|
        output = process_output(stdout, print_output)
        output.concat process_output(stderr, print_output)
        raise "Error running command #{cmd}" unless thread.value.success?
        return output
      end
    end

    private_class_method
    def self.process_output(std, print_output)
      line = ''
      lines = []
      std.each_char do |char|
        print char if print_output
        case char
        when "\r"
          next
        when "\n"
          lines << line
          line = ''
        else
          line << char
        end
      end

      lines << line unless line.empty?
      lines
    end
  end
end
