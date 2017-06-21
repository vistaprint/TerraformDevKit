require 'TerraformDevKit/command'
require 'TerraformDevKit/os'

module TerraformDevKit
  class TerraformEnvManager
    def self.exist?(env)
      output = Command.run('terraform env list')
      output.any? { |line| line.tr('* ', '') == env }
    end

    def self.create(env)
      Command.run("terraform env new #{env}") unless exist?(env)
    end

    def self.delete(env)
      if exist?(env)
        select('default')
        if TerraformDevKit::OS.host_os == 'windows'
          # TODO: Get rid of this hack once the following issue gets fixed:
          # https://github.com/hashicorp/terraform/issues/15343
          puts 'WARNING: Deleting an environment does not work on Windows'
        else
          Command.run("terraform env delete #{env}")
        end
      end
    end

    def self.select(env)
      create(env)
      Command.run("terraform env select #{env}")
    end

    def self.active
      output = Command.run('terraform env list')
      active = output.select { |line| line.include?('*') }
      raise 'Error parsing output from terraform' if active.length != 1
      match = /\s*\*\s*(\S+)/.match(active[0])
      match[1] unless match.nil?
    end
  end
end
