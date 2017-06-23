require 'TerraformDevKit/command'
require 'TerraformDevKit/os'

module TerraformDevKit
  class TerraformEnvManager
    def self.exist?(env)
      output = Command.run('terraform env list', print_output: false)
      output.any? { |line| line.tr('* ', '') == env }
    end

    def self.create(env)
      unless exist?(env)
        Command.run("terraform env new #{env}", print_output: false)
      end
    end

    def self.delete(env)
      if exist?(env)
        select('default')
        Command.run("terraform env delete #{env}", print_output: false)
      end
    rescue RuntimeError => error
      # TODO: Get rid of this hack once the following issue gets fixed:
      # https://github.com/hashicorp/terraform/issues/15343
      puts "Error deleting terraform environment: #{error}\n" \
        'NOTE: Deleting an environment does not currently work on Windows'
    end

    def self.select(env)
      create(env)
      Command.run("terraform env select #{env}", print_output: false)
    end

    def self.active
      output = Command.run('terraform env list', print_output: false)
      active = output.select { |line| line.include?('*') }
      raise 'Error parsing output from terraform' if active.length != 1
      match = /\s*\*\s*(\S+)/.match(active[0])
      match[1] unless match.nil?
    end
  end
end
