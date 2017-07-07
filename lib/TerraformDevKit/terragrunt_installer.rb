require 'fileutils'

require_relative 'download'
require_relative 'os'
require_relative 'command'

module TerraformDevKit
  class TerragruntInstaller
    EXTENSION = (OS.host_os == 'windows' ? '.exe' : '').freeze
    LOCAL_FILE_NAME = "terragrunt#{EXTENSION}".freeze

    def self.installed_terragrunt_version
      version = Command.run('terragrunt --version')[0]
      match = /terragrunt version v(\d+\.\d+\.\d+)/.match(version)
      match[1] unless match.nil?
    rescue
      nil
    end

    def self.install_local(version, directory: Dir.pwd)
      if installed_terragrunt_version == version
        puts 'Terragrunt already installed'
        return
      end

      FileUtils.mkdir_p(directory)
      Dir.chdir(directory) do
        download_terragrunt(version)

        unless TerraformDevKit::OS.host_os == 'windows'
          FileUtils.chmod('u+x', LOCAL_FILE_NAME)
        end
      end
    end

    private_class_method
    def self.download_terragrunt(version)
      TerraformDevKit.download_file(
        "https://github.com/gruntwork-io/terragrunt/releases/download/v#{version}/terragrunt_#{OS.host_os}_amd64#{EXTENSION}",
        LOCAL_FILE_NAME,
        force_download: true
      )
    end
  end
end
