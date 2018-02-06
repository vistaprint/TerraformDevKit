require 'json'

module TerraformDevKit
  class CommandError < StandardError
    attr_reader :cmd
    attr_reader :output

    def initialize(cmd, output)
      @cmd = cmd
      @output = output
      super(JSON.generate({ cmd: @cmd, output: @output.join("\n") }))
    end
  end
end
