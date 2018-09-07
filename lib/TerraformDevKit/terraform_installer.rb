require 'fileutils'
require 'zip'

require_relative 'download'
require_relative 'os'
require_relative 'command'

module TerraformDevKit
  class TerraformInstaller
    LOCAL_FILE_NAME = 'terraform.zip'.freeze

    def self.installed_terraform_version
      extract_version(Command.run('terraform --version'))
    rescue
      nil
    end

    def self.extract_version(output)
      # Terraform vx.y.z might be anywhere in the output (warnings may appear
      # before the version does). Therefore we scan all the lines.

      matches = output.map { |line| /Terraform v(\d+\.\d+\.\d+)/.match(line) }
                      .reject(&:nil?)

      matches.count == 1 ? matches[0][1] : nil
    end

    def self.install_local(version, directory: Dir.pwd)
      if installed_terraform_version == version
        puts 'Terraform already installed'
        return
      end

      FileUtils.mkdir_p(directory)
      Dir.chdir(directory) do
        download_terraform(version)
        unzip_terraform
      end
    end

    private_class_method
    def self.download_terraform(version)
      TerraformDevKit.download_file(
        "https://releases.hashicorp.com/terraform/#{version}/terraform_#{version}_#{OS.host_os}_amd64.zip",
        LOCAL_FILE_NAME,
        force_download: true
      )
    end

    private_class_method
    def self.unzip_terraform
      Zip::File.open(LOCAL_FILE_NAME) do |zip_file|
        zip_file.each do |entry|
          puts "Extracting #{entry.name}"
          entry.restore_permissions = true
          entry.extract(entry.name) { true }
        end
      end
    end
  end
end
