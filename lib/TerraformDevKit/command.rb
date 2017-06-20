require 'open3'

module TerraformDevKit
  class Command
    def self.run(cmd, directory: Dir.pwd, print_output: true)
      output = []

      Open3.popen2e(cmd, chdir: directory) do |_, stdout_and_stderr, thread|
        stdout_and_stderr.each do |line|
          output << line.tr("\r\n", '')
          puts line if print_output
        end

        raise "Error running command #{cmd}" unless thread.value.success?
      end

      output
    end
  end
end
