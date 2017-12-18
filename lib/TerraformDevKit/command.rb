require 'open3'

module TerraformDevKit
  class Command
    def self.run(cmd, directory: Dir.pwd, print_output: true)
      Open3.popen2e(cmd, chdir: directory) do |_, stdout_and_stderr, thread|
        output = process_output(stdout_and_stderr, print_output)

        thread.join
        raise "Error running command #{cmd}" unless thread.value.success?
        return output
      end
    end

    private_class_method
    def self.process_output(stream, print_output)
      lines = []

      until (line = stream.gets).nil?
        print line if print_output
        stream.flush
        lines << line.strip
      end
      lines
    end
  end
end
