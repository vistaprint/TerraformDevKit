require 'open3'

module TerraformDevKit
  class Command
    def self.run(cmd, directory: Dir.pwd, print_output: true)
      Open3.popen3(cmd, chdir: directory) do |_, stdout, stderr, thread|
        output = []
        [stdout, stderr].each do |stream|
          Thread.new {
            output.concat process_output(stream, print_output)
          }.join
        end

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
        lines << line.strip
      end
      lines
    end
  end
end
