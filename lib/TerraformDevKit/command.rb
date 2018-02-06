require 'open3'

require 'TerraformDevKit/errors/command_error'

module TerraformDevKit
  class Command
    def self.run(cmd, directory: Dir.pwd, print_output: true)
      out = IO.popen(cmd, err: %i[child out], chdir: directory) do |io|
        begin
          out = ''
          loop do
            chunk = io.readpartial(4096)
            print chunk if print_output
            out += chunk
          end
        rescue EOFError; end
        out
      end

      out = process_output(out)
      $?.exitstatus.zero? || (raise CommandError.new(cmd, out))
      out
    end

    private_class_method
    def self.process_output(out)
      out.split("\n")
        .map { |line| line.tr("\r\n", '') }
    end
  end
end
