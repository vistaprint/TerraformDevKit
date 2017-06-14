require 'fileutils'
require 'tmpdir'

require 'TerraformDevKit/terraform_installer'

RSpec.describe TerraformDevKit::TerraformInstaller do
  describe '#installed_terraform_version' do
    context 'terraform is not installed' do
      before(:example) do
        allow(TerraformDevKit::Command)
          .to receive(:run)
          .and_throw('Error running command')
      end

      it 'returns nil' do
        version = TerraformDevKit::TerraformInstaller.installed_terraform_version
        expect(version).to be_nil
      end
    end

    context 'terraform is installed' do
      before(:example) do
        allow(TerraformDevKit::Command)
          .to receive(:run)
          .and_return("Terraform v0.9.8\r\n")
      end

      it 'returns the version' do
        version = TerraformDevKit::TerraformInstaller.installed_terraform_version
        expect(version).to eq('0.9.8')
      end
    end
  end

  describe '#install_local' do
    before(:example) do
      allow(TerraformDevKit::Command)
        .to receive(:run)
        .and_throw('Error running command')

      @tmpdir = Dir.mktmpdir
    end

    after(:example) do
      FileUtils.rm_rf(@tmpdir, secure: true)
    end

    it 'returns nil' do
      Dir.chdir(@tmpdir) do
        TerraformDevKit::TerraformInstaller.install_local('0.9.8')

        allow(TerraformDevKit::Command)
          .to receive(:run)
          .and_call_original

        result = TerraformDevKit::Command.run('./terraform --version')
        match = /Terraform v(\d+\.\d+\.\d+)/.match(result)
        version = match[1] unless match.nil?

        expect(version).to eq('0.9.8')
      end
    end
  end
end
